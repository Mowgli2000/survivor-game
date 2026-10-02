extends SceneTree
## Converts the raw RGS_Dev pack into game sprite sheets. Run via tools/bake_sprites.ps1:
##   phase "images": crop (union of frames), downscale, add a neon glow, write strips;
##   phase "resources": after import, write one SpriteSheet .tres per strip.
## Fails loudly when a folder, frame or animation of the recipe is missing.

const RECIPE := "res://tools/sprites/sprites.json"
const OUT_DIR := "res://assets/sprites/"
## Transparent margin around each cell, room for the glow.
const PAD := 8
const GLOW_SHRINK := 6
const GLOW_GAIN := 3.5
const ELITE_GLOW := Color(1.0, 0.8, 0.2)
const GROUND_SIZE := 512


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
	var pack := ProjectSettings.globalize_path("res://" + String(recipe.pack))
	var sprites: Dictionary = recipe.sprites
	for id: String in sprites:
		var def: Dictionary = sprites[id]
		var frames := _load_frames(pack.path_join(def.src), def.anims)
		if frames.is_empty():
			return false
		var cells := _crop_and_scale(frames, int(recipe.height))
		_save_strip(cells, Color(def.glow), id)
		if def.get("elite", false):
			_save_strip(cells, ELITE_GLOW, id + "_elite")
		print("  baked " + id)
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


func _save_strip(cells: Array[Image], glow: Color, id: String) -> void:
	var cw := cells[0].get_width() + PAD * 2
	var ch := cells[0].get_height() + PAD * 2
	var strip := Image.create(cw * cells.size(), ch, false, Image.FORMAT_RGBA8)
	for i in cells.size():
		strip.blit_rect(_with_glow(cells[i], glow), Rect2i(0, 0, cw, ch), Vector2i(i * cw, 0))
	strip.save_png(OUT_DIR + id + ".png")


## Pads the cell and puts a soft neon halo (blurred silhouette) behind it.
func _with_glow(cell: Image, glow: Color) -> Image:
	var w := cell.get_width() + PAD * 2
	var h := cell.get_height() + PAD * 2
	var padded := Image.create(w, h, false, Image.FORMAT_RGBA8)
	padded.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(PAD, PAD))
	# Blur by shrinking and growing back (native, fast).
	var blur := padded.duplicate() as Image
	blur.resize(maxi(1, w / GLOW_SHRINK), maxi(1, h / GLOW_SHRINK), Image.INTERPOLATE_BILINEAR)
	blur.resize(w, h, Image.INTERPOLATE_CUBIC)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var a := clampf(blur.get_pixel(x, y).a * GLOW_GAIN, 0.0, 1.0)
			out.set_pixel(x, y, Color(glow, a * 0.9))
	out.blend_rect(padded, Rect2i(0, 0, w, h), Vector2i.ZERO)
	return out


func _write_resources(recipe: Dictionary) -> bool:
	var sprites: Dictionary = recipe.sprites
	for id: String in sprites:
		var def: Dictionary = sprites[id]
		var ids: Array[String] = [id]
		if def.get("elite", false):
			ids.append(id + "_elite")
		for out_id in ids:
			var texture := load(OUT_DIR + out_id + ".png") as Texture2D
			if texture == null:
				return _fail("strip not imported: " + out_id)
			var sheet := SpriteSheet.new()
			sheet.texture = texture
			var start := 0
			for anim: String in def.anims:
				var parts := String(def.anims[anim]).split(":")
				sheet.animations[StringName(anim)] = Vector3i(start, int(parts[1]), int(parts[2]))
				start += int(parts[1])
			sheet.cell_size = Vector2i(texture.get_width() / start, texture.get_height())
			if ResourceSaver.save(sheet, OUT_DIR + out_id + ".tres") != OK:
				return _fail("cannot save " + out_id)
	print("Resources written.")
	return true


func _fail(message: String) -> bool:
	printerr("bake_sprites: " + message)
	return false
