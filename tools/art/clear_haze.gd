extends SceneTree
## Removes the semi-transparent background haze some generated images keep (a dark
## veil over the whole canvas: a visible rectangle behind the character in game).
## Flood fill from the image border through pixels less opaque than --max-alpha:
## they become fully transparent. The character's outline is opaque, so it stops
## the fill; shadows inside the character are untouched.
## Usage:
##   Godot.exe --headless --path . -s res://tools/art/clear_haze.gd -- --in=<png> [--out=<png>] [--max-alpha=0.55] [--min-island=600]
## Then specks: separate groups of visible pixels smaller than --min-island pixels
## (denser bits of the haze, left floating around the character) are erased too.

func _initialize() -> void:
	var input := ""
	var output := ""
	var max_alpha := 0.55
	var min_island := 600
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			input = arg.trim_prefix("--in=")
		elif arg.begins_with("--out="):
			output = arg.trim_prefix("--out=")
		elif arg.begins_with("--max-alpha="):
			max_alpha = arg.trim_prefix("--max-alpha=").to_float()
		elif arg.begins_with("--min-island="):
			min_island = arg.trim_prefix("--min-island=").to_int()
	if output == "":
		output = input
	var img := Image.load_from_file(input) if input != "" else null
	if img == null:
		printerr("usage: -- --in=<png> [--out=<png>] [--max-alpha=0.55]")
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	var cleared := 0
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if seen[i]:
			continue
		seen[i] = 1
		var x := i % w
		var y := i / w
		if img.get_pixel(x, y).a >= max_alpha:
			continue
		img.set_pixel(x, y, Color(0, 0, 0, 0))
		cleared += 1
		if x > 0: stack.append(i - 1)
		if x < w - 1: stack.append(i + 1)
		if y > 0: stack.append(i - w)
		if y < h - 1: stack.append(i + w)
	var specks := _erase_small_islands(img, min_island)
	img.save_png(output)
	print("haze cleared: %d px (%.0f %%), specks: %d" % [cleared, 100.0 * cleared / (w * h), specks])
	quit(0)


## Erases groups of visible pixels (4-connected) smaller than `min_size`. Returns their count.
func _erase_small_islands(img: Image, min_size: int) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var erased := 0
	var island := PackedInt32Array()
	var stack := PackedInt32Array()
	for start in w * h:
		if seen[start] or img.get_pixel(start % w, start / w).a <= 0.0:
			continue
		island.clear()
		stack.append(start)
		seen[start] = 1
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			island.append(i)
			var x := i % w
			var y := i / w
			for n in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w if y > 0 else -1, i + w if y < h - 1 else -1]:
				if n >= 0 and not seen[n] and img.get_pixel(n % w, n / w).a > 0.0:
					seen[n] = 1
					stack.append(n)
		if island.size() < min_size:
			erased += 1
			for i in island:
				img.set_pixel(i % w, i / w, Color(0, 0, 0, 0))
	return erased
