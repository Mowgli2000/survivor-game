extends SceneTree
## Crops a region of a PNG and enlarges it (checking small UI details).
## Usage: Godot.exe --headless --path . -s res://tools/art/crop_png.gd -- --in=<png> --out=<png> --rect=x,y,w,h [--zoom=3]


func _initialize() -> void:
	var input := ""
	var output := ""
	var rect := Rect2i(0, 0, 100, 100)
	var zoom := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			input = arg.trim_prefix("--in=")
		elif arg.begins_with("--out="):
			output = arg.trim_prefix("--out=")
		elif arg.begins_with("--zoom="):
			zoom = arg.trim_prefix("--zoom=").to_int()
		elif arg.begins_with("--rect="):
			var p := arg.trim_prefix("--rect=").split(",")
			rect = Rect2i(p[0].to_int(), p[1].to_int(), p[2].to_int(), p[3].to_int())
	var image := Image.load_from_file(input)
	var crop := image.get_region(rect)
	crop.resize(rect.size.x * zoom, rect.size.y * zoom, Image.INTERPOLATE_NEAREST)
	crop.save_png(output)
	quit()
