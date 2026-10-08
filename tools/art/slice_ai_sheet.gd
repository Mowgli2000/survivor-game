extends SceneTree
## Cuts an AI-drawn animation strip (one row of N poses on a plain light background,
## see art_tests/animation_ia/) into the frames the sprite baker expects, for frame-by-
## frame animation instead of the procedural one of prepare_ai_sprite.gd:
##   - background removed (same flood fill as prepare_ai_sprite.gd);
##   - the poses found by the empty columns between them (equal slices if that fails);
##   - one scale for every pose and their vertical place kept (the body bob drawn by
##     the artist stays), each pose centered on its torso (the middle band of the
##     figure: legs, arms and hair swinging do not shift it);
##   - specks cleaned: light fringe pixels left around the outline, and bits of the
##     neighbouring poses or of the background (every island but the figure);
##   - the same ground shadow under every frame.
## Usage:
##   Godot.exe --headless --path . -s res://tools/art/slice_ai_sheet.gd -- --in=<strip.png>
##       --id=<sprite folder> --anim=walk --frames=6 [--bg=0.72]
## Output: assets_src/ai/<id>/<anim>_0..N-1.png (then the id in tools/sprites/sprites.json).

const PREPARE := preload("res://tools/art/prepare_ai_sprite.gd")
## Height of the tallest pose in the output frames (same as prepare_ai_sprite.gd).
const MASTER_HEIGHT := 512


func _initialize() -> void:
	var input := ""
	var id := ""
	var anim := ""
	var count := 0
	var bg_luma := 0.72
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			input = arg.trim_prefix("--in=")
		elif arg.begins_with("--id="):
			id = arg.trim_prefix("--id=")
		elif arg.begins_with("--anim="):
			anim = arg.trim_prefix("--anim=")
		elif arg.begins_with("--frames="):
			count = arg.trim_prefix("--frames=").to_int()
		elif arg.begins_with("--bg="):
			bg_luma = arg.trim_prefix("--bg=").to_float()
	if input == "" or id == "" or anim == "" or count <= 0:
		printerr("usage: -- --in=<strip.png> --id=<folder> --anim=<name> --frames=<n> [--bg=0.72]")
		quit(1)
		return
	var sheet := Image.load_from_file(input)
	if sheet == null:
		printerr("cannot read " + input)
		quit(1)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	PREPARE._remove_background(sheet, bg_luma)
	var spans := _find_poses(sheet, count)
	# Common vertical range and scale: the bob between poses is kept.
	var top := sheet.get_height()
	var bottom := 0
	for span in spans:
		var used := sheet.get_region(Rect2i(span.x, 0, span.y - span.x, sheet.get_height())).get_used_rect()
		top = mini(top, used.position.y)
		bottom = maxi(bottom, used.end.y)
	var scale := MASTER_HEIGHT / float(bottom - top)
	var poses: Array[Image] = []
	var centers: Array[float] = []
	var widest := 0
	for span in spans:
		var pose := sheet.get_region(Rect2i(span.x, top, span.y - span.x, bottom - top))
		_clean(pose)
		pose.resize(maxi(1, roundi(pose.get_width() * scale)), MASTER_HEIGHT, Image.INTERPOLATE_LANCZOS)
		poses.append(pose)
		centers.append(_torso_x(pose))
		widest = maxi(widest, pose.get_width())
	var cw := roundi(widest * 1.1)
	var ch := roundi(MASTER_HEIGHT * 1.12)
	var feet_y := ch - roundi(MASTER_HEIGHT * 0.04)
	var out_dir := ProjectSettings.globalize_path("res://assets_src/ai/" + id)
	DirAccess.make_dir_recursive_absolute(out_dir)
	for i in poses.size():
		var canvas := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
		_shadow(canvas, Vector2(cw * 0.5, feet_y), MASTER_HEIGHT * 0.3)
		var pos := Vector2i(roundi(cw * 0.5 - centers[i]), feet_y - MASTER_HEIGHT)
		canvas.blend_rect(poses[i], Rect2i(Vector2i.ZERO, poses[i].get_size()), pos)
		canvas.save_png(out_dir.path_join("%s_%d.png" % [anim, i]))
	print("sliced %d %s frames into %s" % [poses.size(), anim, out_dir])
	quit(0)


## [start x, end x) of each pose: runs of columns holding opaque pixels, merged
## (closest gap first) down to `count`; equal slices when fewer runs are found.
func _find_poses(img: Image, count: int) -> Array[Vector2i]:
	var w := img.get_width()
	var runs: Array[Vector2i] = []
	var start := -1
	for x in w + 1:
		var filled := false
		if x < w:
			for y in range(0, img.get_height(), 2):
				if img.get_pixel(x, y).a > 0.3:
					filled = true
					break
		if filled and start < 0:
			start = x
		elif not filled and start >= 0:
			runs.append(Vector2i(start, x))
			start = -1
	# Specks (a stray pixel of background) are not poses.
	runs = runs.filter(func(r: Vector2i) -> bool: return r.y - r.x > w / (count * 6))
	while runs.size() > count:
		var best := 0
		for i in runs.size() - 1:
			if runs[i + 1].x - runs[i].y < runs[best + 1].x - runs[best].y:
				best = i
		runs[best] = Vector2i(runs[best].x, runs[best + 1].y)
		runs.remove_at(best + 1)
	if runs.size() == count:
		return runs
	var slices: Array[Vector2i] = []
	for i in count:
		slices.append(Vector2i(w * i / count, w * (i + 1) / count))
	return slices


## Removes what is not the figure: light, unsaturated pixels on the edge of the
## transparent area (the white fringe, twice to peel two layers), then every island of
## pixels except the biggest one (the figure) and the big ones not touching the left or
## right side (a separate bit of the figure; touching a side = a neighbouring pose).
func _clean(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for _pass in 2:
		var fringe: Array[Vector2i] = []
		for y in h:
			for x in w:
				var c := img.get_pixel(x, y)
				if c.a <= 0.0 or not _is_light(c):
					continue
				if (x > 0 and img.get_pixel(x - 1, y).a <= 0.0) or (x < w - 1 and img.get_pixel(x + 1, y).a <= 0.0) 						or (y > 0 and img.get_pixel(x, y - 1).a <= 0.0) or (y < h - 1 and img.get_pixel(x, y + 1).a <= 0.0):
					fringe.append(Vector2i(x, y))
		for p in fringe:
			img.set_pixelv(p, Color(0, 0, 0, 0))
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(-1)
	var sizes: Array[int] = []
	var sides: Array[bool] = []
	for start in w * h:
		if label[start] >= 0 or img.get_pixel(start % w, start / w).a < 0.08:
			continue
		var id := sizes.size()
		var count := 0
		var side := false
		var stack := PackedInt32Array([start])
		label[start] = id
		while not stack.is_empty():
			var idx := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			count += 1
			var x := idx % w
			var y := idx / w
			side = side or x == 0 or x == w - 1
			for n: int in [idx - 1 if x > 0 else -1, idx + 1 if x < w - 1 else -1, idx - w if y > 0 else -1,
					idx + w if y < h - 1 else -1]:
				if n >= 0 and label[n] < 0 and img.get_pixel(n % w, n / w).a >= 0.08:
					label[n] = id
					stack.append(n)
		sizes.append(count)
		sides.append(side)
	if sizes.is_empty():
		return
	var biggest := 0
	for i in sizes.size():
		if sizes[i] > sizes[biggest]:
			biggest = i
	for idx in w * h:
		var id := label[idx]
		var keep := id == biggest or (id >= 0 and sizes[id] >= 300 and not sides[id])
		if not keep:
			img.set_pixel(idx % w, idx / w, Color(0, 0, 0, 0))


func _is_light(c: Color) -> bool:
	var hi := maxf(c.r, maxf(c.g, c.b))
	var lo := minf(c.r, minf(c.g, c.b))
	return c.get_luminance() >= 0.6 and hi - lo < 0.18


## Mean x of the opaque pixels between 35 % and 60 % of the height (the torso).
func _torso_x(img: Image) -> float:
	var sum := 0.0
	var n := 0
	for y in range(roundi(img.get_height() * 0.35), roundi(img.get_height() * 0.6), 2):
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				sum += x
				n += 1
	return sum / n if n > 0 else img.get_width() * 0.5


## Soft dark ellipse on the ground under the feet.
func _shadow(canvas: Image, center: Vector2, rx: float) -> void:
	var ry := rx * 0.22
	for y in range(roundi(center.y - ry) - 1, mini(canvas.get_height(), roundi(center.y + ry) + 2)):
		for x in range(roundi(center.x - rx) - 1, roundi(center.x + rx) + 2):
			var dx := (x - center.x) / rx
			var dy := (y - center.y) / maxf(ry, 1.0)
			var d := dx * dx + dy * dy
			if d <= 1.0 and x >= 0 and x < canvas.get_width():
				canvas.set_pixel(x, y, Color(0, 0, 0, 0.35 * (1.0 - d * d)))
