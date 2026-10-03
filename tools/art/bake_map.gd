extends SceneTree
## Rasterizes the arena art drawn by tools/art/make_map.py. Run via tools/bake_sprites.ps1:
##   phase "images": ground.svg -> assets/sprites/ground.png; decor/*.svg packed into
##     assets/map/decor_atlas.png (+ layout json); projectile bodies -> assets/sprites/projectiles.png;
##   phase "resources": after import, writes assets/map/decor_atlas.tres (DecorAtlas).

const SRC := "res://assets_src/drawn/map"
const GROUND_OUT := "res://assets/sprites/ground.png"
const ATLAS := "res://assets/map/decor_atlas.png"
const LAYOUT := "res://tools/art/decor_layout.json"
const RESOURCE := "res://assets/map/decor_atlas.tres"
const PROJECTILES := "res://assets/sprites/projectiles.png"
const PROJECTILE_CELL := 64
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
	var names: Array[String] = []
	for f in DirAccess.get_files_at(SRC.path_join("decor")):
		if f.ends_with(".svg"):
			names.append(f)
	names.sort()
	# Shelf packing: left to right, new row when the width is full.
	var images: Array[Image] = []
	var layout := {}
	var x := 0
	var y := 0
	var row_h := 0
	for f in names:
		var image := _raster(SRC.path_join("decor").path_join(f))
		if image == null:
			return _fail("cannot rasterize " + f)
		if x + image.get_width() > ATLAS_WIDTH:
			x = 0
			y += row_h + PAD
			row_h = 0
		layout[f.get_basename()] = [x, y, image.get_width(), image.get_height()]
		images.append(image)
		x += image.get_width() + PAD
		row_h = maxi(row_h, image.get_height())
	var atlas := Image.create(ATLAS_WIDTH, y + row_h, false, Image.FORMAT_RGBA8)
	var i := 0
	for f in names:
		var rect: Array = layout[f.get_basename()]
		atlas.blit_rect(images[i], Rect2i(Vector2i.ZERO, images[i].get_size()), Vector2i(rect[0], rect[1]))
		i += 1
	atlas.save_png(ATLAS)
	if not _bake_projectiles():
		return false
	var file := FileAccess.open(LAYOUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(layout, "\t"))
	print("Map images baked (%d decor pieces)." % names.size())
	return true


## Projectile bodies: one 64x64 cell per style, in file name order (1_orb...).
func _bake_projectiles() -> bool:
	var dir := "res://assets_src/drawn/projectiles"
	var names: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".svg"):
			names.append(f)
	names.sort()
	if names.is_empty():
		return _fail("missing %s (run python tools/art/make_map.py)" % dir)
	var strip := Image.create(PROJECTILE_CELL * names.size(), PROJECTILE_CELL, false, Image.FORMAT_RGBA8)
	for i in names.size():
		var image := _raster(dir.path_join(names[i]))
		if image == null:
			return _fail("cannot rasterize " + names[i])
		strip.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(i * PROJECTILE_CELL, 0))
	strip.save_png(PROJECTILES)
	return true


func _resources() -> bool:
	var texture := load(ATLAS) as Texture2D
	var layout: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if texture == null or not layout is Dictionary:
		return _fail("decor atlas not baked/imported")
	# Loaded by path: the class cache may not know a freshly added class yet.
	var atlas: Resource = load("res://src/run/decor_atlas.gd").new()
	atlas.texture = texture
	for name: String in layout:
		var r: Array = layout[name]
		atlas.regions[StringName(name)] = Rect2(r[0], r[1], r[2], r[3])
	if ResourceSaver.save(atlas, RESOURCE) != OK:
		return _fail("cannot save " + RESOURCE)
	print("Decor atlas written.")
	return true


func _fail(message: String) -> bool:
	printerr("bake_map: " + message)
	return false
