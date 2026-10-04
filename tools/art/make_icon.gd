extends SceneTree
## Turns a generated image (transparent background) into a square game icon:
## crops to the visible pixels, centers on a square canvas with a small margin,
## then downscales. Weapon icons double as the in-game floating weapon
## (WeaponVisuals), so their art must be horizontal, tip on the right.
## Usage:
##   Godot.exe --headless --path . -s res://tools/art/make_icon.gd -- --in=<png> --out=<png> [--size=128]
## With --height=N instead: crop and scale to N px high, keeping the aspect ratio
## (arena decor, see tools/art/bake_map.gd).

## Empty border around the art, as a fraction of the icon size.
const MARGIN := 0.04


func _initialize() -> void:
	var input := ""
	var output := ""
	var size := 128
	var height := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			input = arg.trim_prefix("--in=")
		elif arg.begins_with("--out="):
			output = arg.trim_prefix("--out=")
		elif arg.begins_with("--size="):
			size = arg.trim_prefix("--size=").to_int()
		elif arg.begins_with("--height="):
			height = arg.trim_prefix("--height=").to_int()
	var source := Image.load_from_file(input) if input != "" else null
	if source == null or output == "":
		printerr("usage: -- --in=<png> --out=<png> [--size=128]")
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var art := source.get_region(source.get_used_rect())
	if height > 0:
		art.resize(roundi(art.get_width() * height / float(art.get_height())), height, Image.INTERPOLATE_LANCZOS)
		art.save_png(output)
		print("decor %s (%dx%d)" % [output, art.get_width(), height])
		quit(0)
		return
	var side := roundi(maxi(art.get_width(), art.get_height()) / (1.0 - MARGIN * 2.0))
	var canvas := Image.create(side, side, false, Image.FORMAT_RGBA8)
	canvas.blit_rect(art, Rect2i(Vector2i.ZERO, art.get_size()),
		Vector2i((side - art.get_width()) / 2, (side - art.get_height()) / 2))
	canvas.resize(size, size, Image.INTERPOLATE_LANCZOS)
	canvas.save_png(output)
	print("icon %s (%dx%d)" % [output, size, size])
	quit(0)
