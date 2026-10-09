extends SceneTree
## Turns a generated image (transparent background) into a square game icon:
## crops to the visible pixels, centers on a square canvas with a small margin,
## then downscales. Weapon icons double as the in-game floating weapon
## (WeaponVisuals), so their art must be horizontal, tip on the right.
## Usage:
##   Godot.exe --headless --path . -s res://tools/art/make_icon.gd -- --in=<png> --out=<png> [--size=128] [--diagonal=1.8]
## --diagonal=R: art at least R times wider than tall (long weapons) is turned 45 degrees,
## tip up-right, so it fills the square and reads bigger in the UI; the output line says
## "diagonal" and the weapon's WeaponData.icon_diagonal must be set (WeaponVisuals turns
## it back for the floating weapon).
## --cut=A: pixels with alpha below A are cleared first (soft halos would inflate the crop).
## With --height=N instead: crop and scale to N px high, keeping the aspect ratio
## (arena decor, see tools/art/bake_map.gd).

## Empty border around the art, as a fraction of the icon size.
const MARGIN := 0.04


func _initialize() -> void:
	var input := ""
	var output := ""
	var size := 128
	var height := 0
	var diagonal_ratio := 0.0
	var cut := 0.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			input = arg.trim_prefix("--in=")
		elif arg.begins_with("--out="):
			output = arg.trim_prefix("--out=")
		elif arg.begins_with("--size="):
			size = arg.trim_prefix("--size=").to_int()
		elif arg.begins_with("--height="):
			height = arg.trim_prefix("--height=").to_int()
		elif arg.begins_with("--cut="):
			cut = arg.trim_prefix("--cut=").to_float()
		elif arg.begins_with("--diagonal="):
			diagonal_ratio = arg.trim_prefix("--diagonal=").to_float()
	var source := Image.load_from_file(input) if input != "" else null
	if source == null or output == "":
		printerr("usage: -- --in=<png> --out=<png> [--size=128]")
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	if cut > 0.0:
		for y in source.get_height():
			for x in source.get_width():
				var px := source.get_pixel(x, y)
				if px.a < cut:
					source.set_pixel(x, y, Color(px, 0.0))
	var art := source.get_region(source.get_used_rect())
	if height > 0:
		art.resize(roundi(art.get_width() * height / float(art.get_height())), height, Image.INTERPOLATE_LANCZOS)
		art.save_png(output)
		print("decor %s (%dx%d)" % [output, art.get_width(), height])
		quit(0)
		return
	var diagonal := diagonal_ratio > 0.0 and art.get_width() >= art.get_height() * diagonal_ratio
	if diagonal:
		art = _turned_up_right(art)
	var side := roundi(maxi(art.get_width(), art.get_height()) / (1.0 - MARGIN * 2.0))
	var canvas := Image.create(side, side, false, Image.FORMAT_RGBA8)
	canvas.blit_rect(art, Rect2i(Vector2i.ZERO, art.get_size()),
		Vector2i((side - art.get_width()) / 2, (side - art.get_height()) / 2))
	canvas.resize(size, size, Image.INTERPOLATE_LANCZOS)
	canvas.save_png(output)
	print("icon %s (%dx%d)%s" % [output, size, size, " diagonal" if diagonal else ""])
	quit(0)


## `art` turned 45 degrees counterclockwise (bilinear), cropped to its pixels.
## Downscaled first: a GDScript loop over a 1536 px image would be slow.
func _turned_up_right(art: Image) -> Image:
	var scale := minf(1.0, 640.0 / art.get_width())
	if scale < 1.0:
		art.resize(roundi(art.get_width() * scale), roundi(art.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var w := art.get_width()
	var h := art.get_height()
	var side := ceili((w + h) / sqrt(2.0)) + 2
	var out := Image.create(side, side, false, Image.FORMAT_RGBA8)
	var c_out := Vector2(side, side) * 0.5
	var c_in := Vector2(w, h) * 0.5
	var turn := Transform2D(PI / 4.0, Vector2.ZERO)  # destination -> source
	for y in side:
		for x in side:
			var p := turn * (Vector2(x, y) - c_out) + c_in
			if p.x < 0.0 or p.y < 0.0 or p.x > w - 1.0 or p.y > h - 1.0:
				continue
			var x0 := floori(p.x)
			var y0 := floori(p.y)
			var x1 := mini(x0 + 1, w - 1)
			var y1 := mini(y0 + 1, h - 1)
			var fx := p.x - x0
			var fy := p.y - y0
			var top := art.get_pixel(x0, y0).lerp(art.get_pixel(x1, y0), fx)
			var bottom := art.get_pixel(x0, y1).lerp(art.get_pixel(x1, y1), fx)
			out.set_pixel(x, y, top.lerp(bottom, fy))
	return out.get_region(out.get_used_rect())
