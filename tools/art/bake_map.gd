extends SceneTree
## Rasterizes the arena art drawn by tools/art/make_map.py. Run via tools/bake_sprites.ps1:
##   phase "images": ground.svg -> assets/sprites/ground.png; each decor set (decor/,
##     decor_<biome>/) packed into assets/map/decor_atlas[_<biome>].png (+ layout json);
##     projectile bodies -> assets/sprites/projectiles.png;
##   phase "resources": after import, writes assets/map/decor_atlas[_<biome>].tres (DecorAtlas).

const SRC := "res://assets_src/drawn/map"
const GROUND_OUT := "res://assets/sprites/ground.png"
const ATLAS := "res://assets/map/decor_atlas.png"
const PROJECTILES := "res://assets/sprites/projectiles.png"
const PROJECTILE_CELL := 128
const PAD := 4
const ATLAS_WIDTH := 1024


func _initialize() -> void:
	var phase := "images"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
	var ok := _images() if phase == "images" else _resources()
	quit(0 if ok else 1)


func _raster(path: String) -> Image:
	var image := Image.new()
	if image.load_svg_from_string(FileAccess.get_file_as_string(path), 1.0) != OK:
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


func _images() -> bool:
	if not FileAccess.file_exists(SRC.path_join("ground.svg")):
		return _fail("missing %s (run python tools/art/make_map.py)" % SRC)
	var ground := _raster(SRC.path_join("ground.svg"))
	if ground == null:
		return _fail("cannot rasterize ground.svg")
	ground.save_png(GROUND_OUT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ATLAS.get_base_dir()))
	# One atlas per decor set: decor/ (default arena) and decor_<biome>/ (seals).
	for set_name in _decor_sets():
		if not _bake_decor(set_name):
			return false
	return _bake_projectiles()


## "decor" and every "decor_<biome>" folder under SRC.
func _decor_sets() -> Array[String]:
	var sets: Array[String] = []
	for d in DirAccess.get_directories_at(SRC):
		if d == "decor" or d.begins_with("decor_"):
			sets.append(d)
	sets.sort()
	return sets


## Atlas, layout json and resource paths of a decor set ("decor" keeps the old names).
func _paths(set_name: String) -> Dictionary:
	var suffix := set_name.trim_prefix("decor")
	return {
		"atlas": "res://assets/map/decor_atlas%s.png" % suffix,
		"layout": "res://tools/art/decor_layout%s.json" % suffix,
		"resource": "res://assets/map/decor_atlas%s.tres" % suffix,
	}


func _bake_decor(set_name: String) -> bool:
	var dir := SRC.path_join(set_name)
	var names: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		# SVG drawn by make_map.py, or PNG made from AI art (tools/art/make_icon.gd --height).
		if f.ends_with(".svg") or f.ends_with(".png"):
			names.append(f)
	names.sort()
	# Shelf packing: left to right, new row when the width is full.
	var images: Array[Image] = []
	var layout := {}
	var x := 0
	var y := 0
	var row_h := 0
	for f in names:
		var path := dir.path_join(f)
		var image := _raster(path) if f.ends_with(".svg") else Image.load_from_file(path)
		if image == null:
			return _fail("cannot rasterize " + f)
		image.convert(Image.FORMAT_RGBA8)
		if x + image.get_width() > ATLAS_WIDTH:
			x = 0
			y += row_h + PAD
			row_h = 0
		layout[f.get_basename()] = [x, y, image.get_width(), image.get_height()]
		images.append(image)
		x += image.get_width() + PAD
		row_h = maxi(row_h, image.get_height())
	var atlas := Image.create(ATLAS_WIDTH, maxi(y + row_h, 1), false, Image.FORMAT_RGBA8)
	var i := 0
	for f in names:
		var rect: Array = layout[f.get_basename()]
		atlas.blit_rect(images[i], Rect2i(Vector2i.ZERO, images[i].get_size()), Vector2i(rect[0], rect[1]))
		i += 1
	var paths := _paths(set_name)
	atlas.save_png(paths.atlas)
	var file := FileAccess.open(paths.layout, FileAccess.WRITE)
	file.store_string(JSON.stringify(layout, "\t"))
	print("Decor %s baked (%d pieces)." % [set_name, names.size()])
	return true


## Projectile bodies: one square cell per style (WeaponData.ProjectileStyle 1..),
## in file name order. AI art PNGs (01_orb.png..., art_source/ai/projectiles/ via
## make_icon.gd) win over the old code-drawn SVGs (make_map.py).
func _bake_projectiles() -> bool:
	var dir := "res://assets_src/drawn/projectiles"
	var names: Array[String] = []
	for ext in [".png", ".svg"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(ext):
				names.append(f)
		if not names.is_empty():
			break
	names.sort()
	if names.is_empty():
		return _fail("missing %s (run python tools/art/make_map.py)" % dir)
	var strip := Image.create(PROJECTILE_CELL * names.size(), PROJECTILE_CELL, false, Image.FORMAT_RGBA8)
	for i in names.size():
		var path := dir.path_join(names[i])
		var image := Image.load_from_file(ProjectSettings.globalize_path(path)) if names[i].ends_with(".png") 			else _raster(path)
		if image == null:
			return _fail("cannot read " + names[i])
		image.convert(Image.FORMAT_RGBA8)
		if image.get_size() != Vector2i(PROJECTILE_CELL, PROJECTILE_CELL):
			image.resize(PROJECTILE_CELL, PROJECTILE_CELL, Image.INTERPOLATE_LANCZOS)
		strip.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(i * PROJECTILE_CELL, 0))
	strip.save_png(PROJECTILES)
	return true


func _resources() -> bool:
	for set_name in _decor_sets():
		var paths := _paths(set_name)
		var texture := load(paths.atlas) as Texture2D
		var layout: Variant = JSON.parse_string(FileAccess.get_file_as_string(paths.layout))
		if texture == null or not layout is Dictionary:
			return _fail("decor atlas %s not baked/imported" % set_name)
		# Loaded by path: the class cache may not know a freshly added class yet.
		var atlas: Resource = load("res://src/run/decor_atlas.gd").new()
		atlas.texture = texture
		for name: String in layout:
			var r: Array = layout[name]
			atlas.regions[StringName(name)] = Rect2(r[0], r[1], r[2], r[3])
		if ResourceSaver.save(atlas, paths.resource) != OK:
			return _fail("cannot save " + paths.resource)
	print("Decor atlases written.")
	return true


func _fail(message: String) -> bool:
	printerr("bake_map: " + message)
	return false
