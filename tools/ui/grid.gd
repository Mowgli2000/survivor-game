extends SceneTree
## Debug: contact sheet. Usage: -s res://tools/ui/grid.gd -- <out.png> <cols> <cell> <in1> <in2> ...
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cols := int(args[1])
	var cell := int(args[2])
	var files := args.slice(3)
	var rows := ceili(files.size() / float(cols))
	var sheet := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.06, 0.1, 0.22))
	for i in files.size():
		var im := Image.load_from_file(files[i])
		im.convert(Image.FORMAT_RGBA8)
		im.resize(cell - 8, cell - 8, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(im, Rect2i(0, 0, cell - 8, cell - 8), Vector2i((i % cols) * cell + 4, (i / cols) * cell + 4))
	sheet.save_png(args[0])
	quit()
