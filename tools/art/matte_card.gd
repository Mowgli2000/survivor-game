extends SceneTree
## Cuts a character illustration drawn on a plain white background out of it, with clean
## edges, and scales it to a card (512x768 by default).
##   - the background is the white connected to the image border (flood fill);
##   - white pockets enclosed by the figure are background too: big near-pure white
##     regions (between a ponytail and a hood), and the thin white slivers the AI leaves
##     between a drawn outline and the edge of the figure (hair, hands);
##   - the edge is un-matted: an edge pixel is the black outline blended with the white
##     background, so its coverage is read from its brightness and its color is brought
##     back to the outline's (otherwise a light halo shows on the dark screens).
## Usage:
##   Godot.exe --headless --path . -s res://tools/art/matte_card.gd -- --in=<png> --out=<png>
##       [--w=512] [--h=768] [--no-slivers] [--erase=x,y,w,h]
## --erase=x,y,w,h: in the source image, every pale pixel of that rectangle is background
## too (a white leftover the rules above cannot tell from a tooth or a white garment).
## --no-slivers: keep the thin white parts near the edge (white hair: the sliver rule takes
## the white edge of a braid for background).
## The figure must have a dark outline (the style of the game's art).

## Pixels at least this bright and unsaturated, reached from the border, are background.
const BACKGROUND_LUMA := 0.72
const BACKGROUND_SATURATION := 0.12
## Enclosed pockets: at least POCKET_MIN pixels with every channel at least POCKET_WHITE.
const POCKET_WHITE := 0.975
const POCKET_MIN := 150
## Slivers: near-white (SLIVER_WHITE), within SLIVER_NEAR pixels of the outside, at least
## SLIVER_MIN pixels and thin (no SLIVER_THICK x SLIVER_THICK square fits in it: a white
## braid or a white garment does).
const SLIVER_WHITE := 0.93
const SLIVER_NEAR := 14
const SLIVER_MIN := 3
const SLIVER_THICK := 9
## --erase removes the pixels brighter than this.
const ERASE_LUMA := 0.8
## Colour of the outline an edge pixel is blended with, and how far the edge band reaches.
const OUTLINE_LUMA := 0.06
const EDGE_REACH := 3
## Pixels of an edge band darker than this keep their colour and are opaque (outline).
const SOLID_LUMA := 0.3


func _initialize() -> void:
	var opts := {"in": "", "out": "", "w": "512", "h": "768"}
	var slivers := true
	var erase := Rect2i()
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2 and opts.has(kv[0]):
			opts[kv[0]] = kv[1]
		elif arg == "--no-slivers":
			slivers = false
		elif arg.begins_with("--erase="):
			var v := arg.trim_prefix("--erase=").split_floats(",")
			erase = Rect2i(int(v[0]), int(v[1]), int(v[2]), int(v[3]))
	if opts["in"] == "" or opts.out == "":
		printerr("usage: -- --in=<png> --out=<png> [--w=512 --h=768]")
		quit(1)
		return
	var img := Image.load_from_file(opts["in"])
	if img == null:
		printerr("cannot read " + opts["in"])
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var erased: Array[Vector2i] = []
	for y in range(erase.position.y, erase.end.y):
		for x in range(erase.position.x, erase.end.x):
			if img.get_pixel(x, y).get_luminance() > ERASE_LUMA:
				erased.append(Vector2i(x, y))
	matte(img, slivers)
	for pixel in erased:
		img.set_pixelv(pixel, Color(0, 0, 0, 0))
	img.resize(int(opts.w), int(opts.h), Image.INTERPOLATE_LANCZOS)
	img.save_png(opts.out)
	quit(0)


## In place: background and pockets transparent, edge un-matted.
static func matte(img: Image, slivers: bool = true) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var gone := PackedByteArray()
	gone.resize(w * h)
	# 1. Background: flood fill from every border pixel.
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	for idx in _region(img, stack, w, h, gone, false):
		gone[idx] = 1
	# 2. Enclosed pockets: big near-pure white ones, and thin slivers near the edge.
	var near := _distance(gone, w, h, SLIVER_NEAR)
	var seen := gone.duplicate()
	for start in w * h:
		if seen[start] == 1 or not _is_white(img.get_pixel(start % w, start / w), SLIVER_WHITE):
			continue
		var pocket := _region(img, PackedInt32Array([start]), w, h, seen, true)
		var remove := false
		if _count_white(img, pocket, w, POCKET_WHITE) >= POCKET_MIN:
			remove = true
		elif slivers and pocket.size() >= SLIVER_MIN:
			var close := false
			for idx in pocket:
				if near[idx] >= 0:
					close = true
					break
			remove = close and not _is_thick(pocket, w, h)
		if remove:
			for idx in pocket:
				gone[idx] = 1
	# 3. Un-matte the edge band: the light pixels between the transparent area and the first
	# dark pixel of the outline (up to EDGE_REACH steps); what is inside the outline is kept.
	var band := PackedByteArray()
	band.resize(w * h)
	var frontier := PackedInt32Array()
	for idx in w * h:
		if gone[idx] == 1:
			frontier.append(idx)
	for _step in EDGE_REACH:
		var next := PackedInt32Array()
		for idx in frontier:
			var x := idx % w
			var y := idx / w
			for n: int in [idx - 1 if x > 0 else -1, idx + 1 if x < w - 1 else -1, idx - w if y > 0 else -1,
					idx + w if y < h - 1 else -1]:
				if n >= 0 and gone[n] == 0 and band[n] == 0 and img.get_pixel(n % w, n / w).get_luminance() > SOLID_LUMA:
					band[n] = 1
					next.append(n)
		frontier = next
	for idx in w * h:
		var x := idx % w
		var y := idx / w
		if gone[idx] == 1:
			img.set_pixel(x, y, Color(0, 0, 0, 0))
		elif band[idx] == 1:
			var c := img.get_pixel(x, y)
			var luma := c.get_luminance()
			if luma <= SOLID_LUMA:
				continue
			# c = a * outline + (1 - a) * white  ->  a from the brightness.
			var a := clampf((1.0 - luma) / (1.0 - OUTLINE_LUMA), 0.0, 1.0)
			if a < 0.1:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var back := Color(minf(maxf((c.r - (1.0 - a)) / a, 0.0), 1.0), minf(maxf((c.g - (1.0 - a)) / a, 0.0), 1.0),
						minf(maxf((c.b - (1.0 - a)) / a, 0.0), 1.0), a)
				img.set_pixel(x, y, back)


## Connected pixels reached from `stack` that look like background (or, `pocket`, like a
## pure white pocket); they are marked in `seen` so that no pixel is walked twice.
static func _region(img: Image, stack: PackedInt32Array, w: int, h: int, seen: PackedByteArray,
		pocket: bool) -> PackedInt32Array:
	var region := PackedInt32Array()
	while not stack.is_empty():
		var idx := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if seen[idx] == 1:
			continue
		var c := img.get_pixel(idx % w, idx / w)
		if not (_is_white(c, SLIVER_WHITE) if pocket else _is_background(c)):
			continue
		seen[idx] = 1
		region.append(idx)
		var x := idx % w
		var y := idx / w
		if x > 0:
			stack.append(idx - 1)
		if x < w - 1:
			stack.append(idx + 1)
		if y > 0:
			stack.append(idx - w)
		if y < h - 1:
			stack.append(idx + w)
	return region


static func _is_background(c: Color) -> bool:
	var hi := maxf(c.r, maxf(c.g, c.b))
	var lo := minf(c.r, minf(c.g, c.b))
	return c.get_luminance() >= BACKGROUND_LUMA and hi - lo < BACKGROUND_SATURATION


static func _is_white(c: Color, white: float) -> bool:
	return minf(c.r, minf(c.g, c.b)) >= white


static func _count_white(img: Image, region: PackedInt32Array, w: int, white: float) -> int:
	var count := 0
	for idx in region:
		if _is_white(img.get_pixel(idx % w, idx / w), white):
			count += 1
	return count


## Steps (up to `reach`) from the removed area through any pixel; -1 when farther.
static func _distance(gone: PackedByteArray, w: int, h: int, reach: int) -> PackedInt32Array:
	var dist := PackedInt32Array()
	dist.resize(w * h)
	dist.fill(-1)
	var frontier := PackedInt32Array()
	for idx in w * h:
		if gone[idx] == 1:
			dist[idx] = 0
			frontier.append(idx)
	for step in range(1, reach + 1):
		var next := PackedInt32Array()
		for idx in frontier:
			var x := idx % w
			var y := idx / w
			for n: int in [idx - 1 if x > 0 else -1, idx + 1 if x < w - 1 else -1, idx - w if y > 0 else -1,
					idx + w if y < h - 1 else -1]:
				if n >= 0 and dist[n] < 0:
					dist[n] = step
					next.append(n)
		frontier = next
	return dist


## True when a SLIVER_THICK x SLIVER_THICK square fits inside `region`.
static func _is_thick(region: PackedInt32Array, w: int, h: int) -> bool:
	var inside := {}
	for idx in region:
		inside[idx] = true
	var half := SLIVER_THICK / 2
	for idx in region:
		var x := idx % w
		var y := idx / w
		var full := true
		for dy in range(-half, half + 1):
			for dx in range(-half, half + 1):
				if not inside.has((y + dy) * w + x + dx):
					full = false
					break
			if not full:
				break
		if full:
			return true
	return false
