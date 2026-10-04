extends SceneTree
## Turns ONE character illustration (AI or artist, plain light background) into
## the frames the sprite baker expects (tools/sprites/bake_sprites.gd, "src" entries):
##   - background removed by flood fill from the borders (light, unsaturated pixels),
##     so whites inside the character (eyes, highlights) are kept;
##   - cropped, optionally mirrored so the character faces right (art default);
##   - procedural animation, Brotato-style (no limb animation needed: weapons
##     float around the player): idle = breathing, walk = small hops with squash.
##   - a soft ground shadow that stays on the floor while the body hops.
## Usage:
##   Godot.exe --headless --path . -s res://tools/art/prepare_ai_sprite.gd -- --in=<image> --id=<sprite_id> [--flip] [--bg=0.72]
## Output: assets_src/ai/<id>/idle_0..5.png and walk_0..7.png (then add the id to
## tools/sprites/sprites.json and run tools/bake_sprites.ps1).

const MASTER_HEIGHT := 512
const IDLE_FRAMES := 6
const WALK_FRAMES := 8
## Hop height and squash, relative to the character height.
const HOP := 0.06
const SQUASH := 0.06
const BREATH := 0.018


func _initialize() -> void:
	var input := ""
	var id := ""
	var flip := false
	var bg_luma := 0.72
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			input = arg.trim_prefix("--in=")
		elif arg.begins_with("--id="):
			id = arg.trim_prefix("--id=")
		elif arg == "--flip":
			flip = true
		elif arg.begins_with("--bg="):
			bg_luma = arg.trim_prefix("--bg=").to_float()
	if input == "" or id == "":
		printerr("usage: -- --in=<image> --id=<sprite_id> [--flip] [--bg=0.72]")
		quit(1)
		return
	var source := Image.load_from_file(input)
	if source == null:
		printerr("cannot read " + input)
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	_remove_background(source, bg_luma)
	var used := source.get_used_rect()
	var body := source.get_region(used)
	if flip:
		body.flip_x()
	var w := roundi(body.get_width() * MASTER_HEIGHT / float(body.get_height()))
	body.resize(w, MASTER_HEIGHT, Image.INTERPOLATE_LANCZOS)

	var out_dir := ProjectSettings.globalize_path("res://assets_src/ai/" + id)
	DirAccess.make_dir_recursive_absolute(out_dir)
	for i in IDLE_FRAMES:
		var s := sin(TAU * i / IDLE_FRAMES)
		_frame(body, 1.0 - s * BREATH * 0.5, 1.0 + s * BREATH, 0.0).save_png(out_dir.path_join("idle_%d.png" % i))
	for i in WALK_FRAMES:
		var p := float(i) / WALK_FRAMES
		var hop := absf(sin(TAU * p))  # two hops per cycle (one per step)
		var squash := 1.0 - hop  # 1 on contact, 0 at the top of the hop
		var sy := 1.0 - squash * SQUASH + hop * SQUASH * 0.5
		var sx := 1.0 + squash * SQUASH * 0.8 - hop * SQUASH * 0.3
		_frame(body, sx, sy, hop * HOP).save_png(out_dir.path_join("walk_%d.png" % i))
	print("prepared %s: %d idle + %d walk frames in %s" % [id, IDLE_FRAMES, WALK_FRAMES, out_dir])
	quit(0)


## Flood fill from every border pixel through light, unsaturated pixels -> transparent.
## Pixels next to the removed area get a partial alpha (soft edge, no white fringe).
func _remove_background(img: Image, luma_min: float) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var removed := PackedByteArray()
	removed.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var idx := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if removed[idx] == 1:
			continue
		var x := idx % w
		var y := idx / w
		if not _is_background(img.get_pixel(x, y), luma_min):
			continue
		removed[idx] = 1
		if x > 0: stack.append(idx - 1)
		if x < w - 1: stack.append(idx + 1)
		if y > 0: stack.append(idx - w)
		if y < h - 1: stack.append(idx + w)
	for y in h:
		for x in w:
			var idx := y * w + x
			if removed[idx] == 1:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			# Edge pixel: fade it by how light it is (anti-aliased outline on white).
			var edge := (x > 0 and removed[idx - 1] == 1) or (x < w - 1 and removed[idx + 1] == 1) \
				or (y > 0 and removed[idx - w] == 1) or (y < h - 1 and removed[idx + w] == 1)
			if edge:
				var c := img.get_pixel(x, y)
				var keep := clampf((1.0 - c.get_luminance()) * 2.5, 0.25, 1.0)
				img.set_pixel(x, y, Color(c.r, c.g, c.b, keep))


func _is_background(c: Color, luma_min: float) -> bool:
	var hi := maxf(c.r, maxf(c.g, c.b))
	var lo := minf(c.r, minf(c.g, c.b))
	return c.get_luminance() >= luma_min and hi - lo < 0.12


## One frame: body scaled (sx, sy) around its feet and lifted by `lift` (fraction of
## the height), on a fixed canvas with the ground shadow.
func _frame(body: Image, sx: float, sy: float, lift: float) -> Image:
	var bw := body.get_width()
	var bh := body.get_height()
	var cw := roundi(bw * 1.2)
	var ch := roundi(bh * 1.16)
	var feet_y := ch - roundi(bh * 0.04)
	var canvas := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
	# Ground shadow (stays on the floor; smaller while the body is in the air).
	var rx := bw * 0.36 * (1.0 - lift * 2.0)
	var ry := rx * 0.22
	for y in range(feet_y - roundi(ry) - 1, mini(ch, feet_y + roundi(ry) + 2)):
		for x in range(roundi(cw * 0.5 - rx) - 1, roundi(cw * 0.5 + rx) + 2):
			var dx := (x - cw * 0.5) / rx
			var dy := (y - feet_y) / maxf(ry, 1.0)
			var d := dx * dx + dy * dy
			if d <= 1.0 and x >= 0 and x < cw:
				canvas.set_pixel(x, y, Color(0, 0, 0, 0.35 * (1.0 - d * d)))
	var scaled := body.duplicate() as Image
	var w := maxi(1, roundi(bw * sx))
	var h := maxi(1, roundi(bh * sy))
	scaled.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var pos := Vector2i(roundi((cw - w) * 0.5), feet_y - h - roundi(lift * bh))
	canvas.blend_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), pos)
	return canvas
