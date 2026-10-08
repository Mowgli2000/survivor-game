extends SceneTree
## Makes the plain white background of a generated image transparent: the near-white
## pixels connected to the border are cleared (a soft edge keeps the outline clean);
## white inside the art (sparkles, highlights) stays, the black outline closes it off.
## Usage: Godot.exe --headless --path . -s res://tools/art/white_to_alpha.gd -- --in=<png> --out=<png>

const WHITE_FROM := 0.9


func _initialize() -> void:
	var input := ""
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			input = arg.trim_prefix("--in=")
		elif arg.begins_with("--out="):
			output = arg.trim_prefix("--out=")
	var image := Image.load_from_file(input)
	image.convert(Image.FORMAT_RGBA8)
	var w := image.get_width()
	var h := image.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen[p.y * w + p.x] == 1:
			continue
		var c := image.get_pixelv(p)
		if minf(c.r, minf(c.g, c.b)) < WHITE_FROM:
			continue
		seen[p.y * w + p.x] = 1
		image.set_pixelv(p, Color(c, 0.0))
		stack.append(p + Vector2i(1, 0))
		stack.append(p + Vector2i(-1, 0))
		stack.append(p + Vector2i(0, 1))
		stack.append(p + Vector2i(0, -1))
	# One pixel of soft edge: opaque pixels touching the cleared area get half alpha when light.
	var copy := image.duplicate() as Image
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c := copy.get_pixel(x, y)
			if c.a < 1.0:
				continue
			var near_clear := copy.get_pixel(x + 1, y).a == 0.0 or copy.get_pixel(x - 1, y).a == 0.0 \
				or copy.get_pixel(x, y + 1).a == 0.0 or copy.get_pixel(x, y - 1).a == 0.0
			if near_clear and minf(c.r, minf(c.g, c.b)) > 0.7:
				image.set_pixel(x, y, Color(c, 0.5))
	image.save_png(output)
	quit()
