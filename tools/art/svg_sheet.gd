extends SceneTree
## Lays SVG files side by side on one PNG sheet (icon mockups).
## Usage: Godot --headless --path . -s res://tools/art/svg_sheet.gd -- --out=<png> --scale=1.0 a.svg b.svg ...


func _init() -> void:
	var out := "res://art_tests/svg_sheet.png"
	var scale := 1.0
	var files: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--scale="):
			scale = arg.trim_prefix("--scale=").to_float()
		elif not arg.begins_with("--"):
			files.append(arg)
	var images: Array[Image] = []
	for file in files:
		var image := Image.new()
		image.load_svg_from_string(FileAccess.get_file_as_string(file), scale)
		images.append(image)
	var size := 0
	for image in images:
		size = maxi(size, maxi(image.get_width(), image.get_height()))
	var gap := 24
	var sheet := Image.create(images.size() * (size + gap) + gap, size + gap * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.16, 0.12, 0.3))
	for i in images.size():
		sheet.blend_rect(images[i], Rect2i(Vector2i.ZERO, images[i].get_size()), Vector2i(gap + i * (size + gap), gap))
	sheet.save_png(out)
	quit()
