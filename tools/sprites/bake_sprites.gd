extends SceneTree
## Converts the drawn SVG frames (tools/art/make_sprites.py, entries with "svg")
## or a raw PNG pack (entries with "src") into game sprite sheets. Run via tools/bake_sprites.ps1:
##   phase "images": crop (union of frames), downscale, add a neon glow, stack every
##     strip into one atlas (atlas.png) and record the layout;
##   phase "resources": after import, write one SpriteSheet .tres per strip.
## Fails loudly when a folder, frame or animation of the recipe is missing.

const RECIPE := "res://tools/sprites/sprites.json"
const OUT_DIR := "res://assets/sprites/"
const ATLAS := "res://assets/sprites/atlas.png"
## Strip positions in the atlas, written by phase "images", read by "resources".
const LAYOUT := "res://tools/sprites/atlas_layout.json"
## Transparent margin around each cell, room for the glow.
const PAD := 8
const GLOW_SHRINK := 6
const GLOW_GAIN := 3.5
const ELITE_GLOW := Color(1.0, 0.8, 0.2)
const GROUND_SIZE := 512
## SVG frames are rasterized at this scale before cropping and downscaling.
const SVG_SCALE := 1.0


func _initialize() -> void:
	var phase := "images"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
	var recipe: Variant = JSON.parse_string(FileAccess.get_file_as_string(RECIPE))
	if not recipe is Dictionary:
		_fail("cannot read " + RECIPE)
		quit(1)
		return
	var ok := _bake_images(recipe) if phase == "images" else _write_resources(recipe)
	quit(0 if ok else 1)


func _bake_images(recipe: Dictionary) -> bool:
	var pack := ProjectSettings.globalize_path("res://" + String(recipe.get("pack", "")))
	var sprites: Dictionary = recipe.sprites
	var strips: Dictionary = {}  # id -> Image
	var cell_widths: Dictionary = {}  # id -> int
	for id: String in sprites:
		var def: Dictionary = sprites[id]
		var frames := _load_svg_frames(ProjectSettings.globalize_path("res://" + String(def.svg)), def.anims) 			if def.has("svg") else _load_frames(pack.path_join(def.src), def.anims)
		if frames.is_empty():
			return false
		# Per-sprite "height" override: bigger on screen = baked bigger (stays sharp).
		var cells := _crop_and_scale(frames, int(def.get("height", recipe.height)))
		strips[id] = _make_strip(cells, Color(def.glow))
		cell_widths[id] = cells[0].get_width() + PAD * 2
		if def.get("elite", false):
			strips[id + "_elite"] = _make_strip(cells, ELITE_GLOW)
			cell_widths[id + "_elite"] = cell_widths[id]
		print("  baked " + id)
	_save_atlas(strips, cell_widths)
	if recipe.has("ground"):
		var ground := Image.load_from_file(pack.path_join(recipe.ground))
		if ground == null:
			return _fail("missing ground " + String(recipe.ground))
		ground.resize(GROUND_SIZE, GROUND_SIZE, Image.INTERPOLATE_LANCZOS)
		ground.save_png(OUT_DIR + "ground.png")
	print("Images baked.")
	return true


## Frames of every animation, in recipe order. Empty array on error.
func _load_frames(dir: String, anims: Dictionary) -> Array[Image]:
	var frames: Array[Image] = []
	if not DirAccess.dir_exists_absolute(dir):
		_fail("missing folder " + dir)
		return frames
	for anim: String in anims:
		var parts := String(anims[anim]).split(":")
		if parts.size() != 3:
			_fail("bad animation spec '%s' (expected source:frames:fps)" % anims[anim])
			return []
		for i in int(parts[1]):
			var path := dir.path_join("%s_%d.png" % [parts[0], i])
			if not FileAccess.file_exists(path):
				_fail("missing frame " + path)
				return []
			var image := Image.load_from_file(path)
			if image == null:
				_fail("cannot read frame " + path)
				return []
			image.convert(Image.FORMAT_RGBA8)
			frames.append(image)
	return frames


## SVG frames "<anim>_<i>.svg" (animation spec "source:frames:fps", source = anim name).
func _load_svg_frames(dir: String, anims: Dictionary) -> Array[Image]:
	var frames: Array[Image] = []
	if not DirAccess.dir_exists_absolute(dir):
		_fail("missing folder %s (run python tools/art/make_sprites.py)" % dir)
		return frames
	for anim: String in anims:
		var parts := String(anims[anim]).split(":")
		if parts.size() != 3:
			_fail("bad animation spec '%s' (expected source:frames:fps)" % anims[anim])
			return []
		for i in int(parts[1]):
			var path := dir.path_join("%s_%d.svg" % [parts[0], i])
			if not FileAccess.file_exists(path):
				_fail("missing frame " + path)
				return []
			var image := Image.new()
			if image.load_svg_from_string(FileAccess.get_file_as_string(path), SVG_SCALE) != OK:
				_fail("cannot rasterize " + path)
				return []
			image.convert(Image.FORMAT_RGBA8)
			frames.append(image)
	return frames


## Crops every frame to the union of their used rects, then scales to `height`.
func _crop_and_scale(frames: Array[Image], height: int) -> Array[Image]:
	var union := frames[0].get_used_rect()
	for image in frames:
		union = union.merge(image.get_used_rect())
	var width := maxi(1, roundi(union.size.x * height / float(union.size.y)))
	var cells: Array[Image] = []
	for image in frames:
		var cell := image.get_region(union)
		cell.resize(width, height, Image.INTERPOLATE_LANCZOS)
		cells.append(cell)
	return cells


func _make_strip(cells: Array[Image], glow: Color) -> Image:
	var cw := cells[0].get_width() + PAD * 2
	var ch := cells[0].get_height() + PAD * 2
	var strip := Image.create(cw * cells.size(), ch, false, Image.FORMAT_RGBA8)
	for i in cells.size():
		strip.blit_rect(_with_glow(cells[i], glow), Rect2i(0, 0, cw, ch), Vector2i(i * cw, 0))
	return strip


## Stacks the strips vertically (recipe order) into one texture; writes the layout.
func _save_atlas(strips: Dictionary, cell_widths: Dictionary) -> void:
	var width := 0
	var height := 0
	for id: String in strips:
		var strip: Image = strips[id]
		width = maxi(width, strip.get_width())
		height += strip.get_height()
	var atlas := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var layout: Dictionary = {}
	var y := 0
	for id: String in strips:
		var strip: Image = strips[id]
		atlas.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(0, y))
		layout[id] = [0, y, cell_widths[id], strip.get_height()]
		y += strip.get_height()
	atlas.save_png(ATLAS)
	var file := FileAccess.open(LAYOUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(layout, "	"))


## Pads the cell and puts a soft neon halo (blurred silhouette) behind it.
func _with_glow(cell: Image, glow: Color) -> Image:
	var w := cell.get_width() + PAD * 2
	var h := cell.get_height() + PAD * 2
	var padded := Image.create(w, h, false, Image.FORMAT_RGBA8)
	padded.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(PAD, PAD))
	# Fully transparent glow ("#00000000", AI sprites): the art has its own clean outline.
	if glow.a <= 0.0:
		return padded
	# Blur by shrinking and growing back (native, fast).
	var blur := padded.duplicate() as Image
	blur.resize(maxi(1, w / GLOW_SHRINK), maxi(1, h / GLOW_SHRINK), Image.INTERPOLATE_BILINEAR)
	blur.resize(w, h, Image.INTERPOLATE_CUBIC)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var a := clampf(blur.get_pixel(x, y).a * GLOW_GAIN, 0.0, 1.0)
			out.set_pixel(x, y, Color(glow, a * 0.9 * glow.a))
	out.blend_rect(padded, Rect2i(0, 0, w, h), Vector2i.ZERO)
	return out


func _write_resources(recipe: Dictionary) -> bool:
	var texture := load(ATLAS) as Texture2D
	var layout: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if texture == null or not layout is Dictionary:
		return _fail("atlas not baked/imported: run phase images then --import")
	var sprites: Dictionary = recipe.sprites
	for id: String in sprites:
		var def: Dictionary = sprites[id]
		var ids: Array[String] = [id]
		if def.get("elite", false):
			ids.append(id + "_elite")
		for out_id in ids:
			if not layout.has(out_id):
				return _fail("%s not in the atlas layout: run the whole bake_sprites.ps1" % out_id)
			var rect: Array = layout[out_id]
			var sheet := SpriteSheet.new()
			sheet.texture = texture
			sheet.origin = Vector2i(int(rect[0]), int(rect[1]))
			sheet.cell_size = Vector2i(int(rect[2]), int(rect[3]))
			var start := 0
			for anim: String in def.anims:
				var parts := String(def.anims[anim]).split(":")
				sheet.animations[StringName(anim)] = Vector3i(start, int(parts[1]), int(parts[2]))
				start += int(parts[1])
			if ResourceSaver.save(sheet, OUT_DIR + out_id + ".tres") != OK:
				return _fail("cannot save " + out_id)
	print("Resources written.")
	return true


func _fail(message: String) -> bool:
	printerr("bake_sprites: " + message)
	return false
