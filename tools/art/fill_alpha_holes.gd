extends SceneTree
## Fixes a known gpt-image-1 defect on transparent backgrounds: dark shadows and
## aura glows inside the character come out semi-transparent, so the UI shows
## through the legs, coat or hat. Pixels that are not fully opaque and NOT
## connected to the image border through transparent pixels are "holes": they
## are made opaque, composited over a dark backdrop (the shadow the AI meant).
## Usage:
##   Godot.exe --headless --path . -s res://tools/art/fill_alpha_holes.gd -- --in=<png> [--out=<png>] [--backdrop=#120d1c]
## Without --out the input file is overwritten. --keep-holes (objects, weapons, decor):
## fully transparent enclosed areas are real holes (inside a ring, a bow) and are kept;
## for characters they are AI defects (see-through legs) and are filled.

## A pixel at or below this alpha lets the outside flood through.
const OUTSIDE_ALPHA := 0.5
## Pixels above this alpha are left as they are.
const OPAQUE_ALPHA := 0.95
## With --keep-holes, pixels at or below this alpha are real holes, left transparent.
const HOLE_ALPHA := 0.05


func _initialize() -> void:
	var input := ""
	var output := ""
	var backdrop := Color("#120d1c")
	var keep_holes := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			input = arg.trim_prefix("--in=")
		elif arg.begins_with("--out="):
			output = arg.trim_prefix("--out=")
		elif arg == "--keep-holes":
			keep_holes = true
		elif arg.begins_with("--backdrop="):
			backdrop = Color(arg.trim_prefix("--backdrop="))
	if input == "":
		printerr("usage: -- --in=<png> [--out=<png>] [--backdrop=#120d1c]")
		quit(1)
		return
	var img := Image.load_from_file(input)
	if img == null:
		printerr("cannot read " + input)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var filled := fill_holes(img, backdrop, keep_holes)
	img.save_png(output if output != "" else input)
	print("filled %d hole pixels in %s" % [filled, input])
	quit(0)


## Makes the enclosed semi-transparent pixels opaque; returns how many changed.
static func fill_holes(img: Image, backdrop: Color, keep_holes: bool = false) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var outside := PackedByteArray()
	outside.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if outside[i] == 1:
			continue
		var x := i % w
		var y := i / w
		if img.get_pixel(x, y).a > OUTSIDE_ALPHA:
			continue
		outside[i] = 1
		if x > 0: stack.append(i - 1)
		if x < w - 1: stack.append(i + 1)
		if y > 0: stack.append(i - w)
		if y < h - 1: stack.append(i + w)
	var filled := 0
	for y in h:
		for x in w:
			if outside[y * w + x] == 1:
				continue
			var c := img.get_pixel(x, y)
			if c.a >= OPAQUE_ALPHA or keep_holes and c.a <= HOLE_ALPHA:
				continue
			var rgb := backdrop.lerp(Color(c.r, c.g, c.b), c.a)
			img.set_pixel(x, y, Color(rgb.r, rgb.g, rgb.b, 1.0))
			filled += 1
	return filled
