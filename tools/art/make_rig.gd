extends SceneTree
## Cuts a character puppet out of a parts sheet (ADR 0020).
## Input: tools/art/rigs/<id>.json (see its "_doc") and the transparent parts sheet.
## Output: assets/rigs/<id>.png (all pieces, scaled to "height" px of body) and
## assets/rigs/<id>.tres (RigData). Then import: Godot.exe --headless --path . --import
## Usage: Godot.exe --headless --path . -s res://tools/art/make_rig.gd -- --id=ronin

const PADDING := 4


func _initialize() -> void:
	var id := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--id="):
			id = arg.trim_prefix("--id=")
	var spec: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/rigs/%s.json" % id))
	if id == "" or not spec is Dictionary:
		printerr("usage: -- --id=<rig id> (tools/art/rigs/<id>.json)")
		quit(1)
		return
	var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://" + spec.sheet))
	sheet.convert(Image.FORMAT_RGBA8)
	var axis: float = spec.get("axis", 0.0)
	var feet := _vec(spec.feet)
	var mirrored := {}
	for p: Dictionary in spec.pieces:
		if p.get("mirror", false):
			mirrored[p.name] = true
	var pieces: Array[Dictionary] = []
	for p: Dictionary in spec.pieces:
		if p.get("mirror", false):
			pieces.append(_side(p, "_l", false, axis, mirrored))
			pieces.append(_side(p, "_r", true, axis, mirrored))
		else:
			pieces.append(p.duplicate())
	pieces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.z < b.z)

	# Cut every piece at sheet resolution, then measure the body height.
	var top := INF
	for p in pieces:
		p.image = _cut(sheet, _vec(p.seed), p.get("cut_above", -1.0), p.get("cut_below", -1.0))
		p.image_rect = _last_rect
		if _last_rect.size.x < 8 or _last_rect.size.y < 8:
			printerr("piece %s: seed %s is not inside a piece" % [p.name, p.seed])
			quit(1)
			return
		# Joint inside the piece (sheet px), mirrored with the piece when flipped.
		var pivot := _vec(p.pivot) - Vector2(_last_rect.position)
		if p.get("flip", false):
			p.image.flip_x()
			pivot.x = _last_rect.size.x - pivot.x
		p.pivot_local = pivot
		var shade: float = p.get("shade", 1.0)
		if shade < 1.0:
			_darken(p.image, shade)
		# Highest point of the assembled body (for the scale).
		top = minf(top, p.at[1] - pivot.y)
	var scale: float = spec.height / (feet.y - top)

	# Scale and pack the pieces side by side.
	var x := 0
	var atlas_h := 0
	for p in pieces:
		var img: Image = p.image
		# 'scale' in the piece: shrink a piece drawn too big (long arms).
		var k: float = scale * p.get("scale", 1.0)
		p.k = k
		var size := Vector2i(maxi(1, roundi(img.get_width() * k)), maxi(1, roundi(img.get_height() * k)))
		img.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		p.region = Rect2i(x, 0, size.x, size.y)
		x += size.x + PADDING
		atlas_h = maxi(atlas_h, size.y)
	var atlas := Image.create_empty(x, atlas_h, false, Image.FORMAT_RGBA8)
	for p in pieces:
		atlas.blit_rect(p.image, Rect2i(Vector2i.ZERO, p.region.size), p.region.position)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/rigs"))
	atlas.save_png(ProjectSettings.globalize_path("res://assets/rigs/%s.png" % id))
	var import_path := ProjectSettings.globalize_path("res://assets/rigs/%s.png.import" % id)
	if not FileAccess.file_exists(import_path):
		# Mipmaps: the puppet is drawn ~2x smaller than its texture.
		var f := FileAccess.open(import_path, FileAccess.WRITE)
		f.store_string("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[params]\n\nmipmaps/generate=true\n")

	var names := PackedStringArray()
	var parents := PackedStringArray()
	var regions := PackedStringArray()
	var pivots := PackedStringArray()
	var joints := PackedStringArray()
	var rests := PackedStringArray()
	for p in pieces:
		rests.append("%.4f" % deg_to_rad(p.get("rest", 0.0)))
		names.append('"%s"' % p.name)
		parents.append('"%s"' % p.parent)
		var r: Rect2i = p.region
		regions.append("Rect2(%d, %d, %d, %d)" % [r.position.x, r.position.y, r.size.x, r.size.y])
		var pivot: Vector2 = p.pivot_local * p.k
		pivots.append("%.2f, %.2f" % [pivot.x, pivot.y])
		var joint: Vector2 = (_vec(p.at) - feet) * scale
		joints.append("%.2f, %.2f" % [joint.x, joint.y])
	var tres := "[gd_resource type=\"Resource\" script_class=\"RigData\" load_steps=3 format=3]\n\n"
	tres += "[ext_resource type=\"Script\" path=\"res://src/player/rig/rig_data.gd\" id=\"1_script\"]\n"
	tres += "[ext_resource type=\"Texture2D\" path=\"res://assets/rigs/%s.png\" id=\"2_tex\"]\n\n" % id
	tres += "[resource]\nscript = ExtResource(\"1_script\")\ntexture = ExtResource(\"2_tex\")\n"
	tres += "names = PackedStringArray(%s)\n" % ", ".join(names)
	tres += "parents = PackedStringArray(%s)\n" % ", ".join(parents)
	tres += "regions = Array[Rect2]([%s])\n" % ", ".join(regions)
	tres += "pivots = PackedVector2Array(%s)\n" % ", ".join(pivots)
	tres += "joints = PackedVector2Array(%s)\n" % ", ".join(joints)
	tres += "rests = PackedFloat32Array(%s)\n" % ", ".join(rests)
	tres += "height = %.1f\n" % spec.height
	var out := FileAccess.open(ProjectSettings.globalize_path("res://assets/rigs/%s.tres" % id), FileAccess.WRITE)
	out.store_string(tres)
	print("rig %s: %d pieces, atlas %dx%d, scale %.3f" % [id, pieces.size(), x, atlas_h, scale])
	quit()


## One side of a mirrored piece: "_l" keeps the sheet piece, "_r" uses its twin
## (the parent too when it is mirrored).
func _side(p: Dictionary, suffix: String, twin: bool, axis: float, mirrored: Dictionary) -> Dictionary:
	var out := p.duplicate()
	out.name = p.name + suffix
	if mirrored.has(p.parent):
		out.parent = p.parent + suffix
	if twin:
		for key in ["seed", "pivot", "at"]:
			out[key] = [2.0 * axis - p[key][0], p[key][1]]
	return out


## The connected opaque area around `seed` (optionally only rows above/below a cut),
## as an image of its bounding box; the box goes to `_last_rect`.
func _cut(sheet: Image, seed: Vector2, cut_above: float, cut_below: float) -> Image:
	var w := sheet.get_width()
	var h := sheet.get_height()
	var inside := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= w or y >= h or sheet.get_pixel(x, y).a < 0.02:
			return false
		if cut_above >= 0.0 and y < cut_above:
			return false
		return cut_below < 0.0 or y < cut_below
	var seen := {}
	var stack: Array[Vector2i] = [Vector2i(seed)]
	var rect := Rect2i(Vector2i(seed), Vector2i.ONE)
	while not stack.is_empty():
		var q: Vector2i = stack.pop_back()
		if seen.has(q) or not inside.call(q.x, q.y):
			continue
		seen[q] = true
		rect = rect.expand(q)
		stack.append_array([q + Vector2i.RIGHT, q + Vector2i.LEFT, q + Vector2i.DOWN, q + Vector2i.UP])
	rect.size += Vector2i.ONE
	var img := Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	for q: Vector2i in seen:
		img.set_pixelv(q - rect.position, sheet.get_pixelv(q))
	_last_rect = rect
	return img


var _last_rect := Rect2i()


func _darken(img: Image, factor: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, Color(c.r * factor, c.g * factor, c.b * factor, c.a))


static func _vec(a: Array) -> Vector2:
	return Vector2(a[0], a[1])
