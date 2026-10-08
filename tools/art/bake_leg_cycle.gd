extends SceneTree
## Run cycle with legs that truly alternate (the image AI always puts the same leg in
## front, playtest 2026-10-08). The upper body comes from the AI (one strip of poses with
## the legs removed: arms, hair and torso keep their drawn motion); each leg is two AI
## drawn pieces (thigh, shin with the boot) turned by a gait table, the far leg half a
## cycle later, darker and behind. The result is a strip for slice_ai_sheet.gd.
## Usage:
##   Godot.exe --headless --path . -s res://tools/art/bake_leg_cycle.gd -- --upper=<strip.png>
##       --parts=<thigh and shin sheet.png> --frames=8 --out=<strip.png> [--leg=0.62]
##       [--hip-in=0.08] [--spread=0.26] [--swing=34] [--knee=95]
## --leg: leg length (hip joint to sole) as a share of the upper body height; --hip-in:
## how far up inside the shorts the hip joints are; --spread: distance between the two
## hips as a share of the shorts width; --swing / --knee: largest hip and knee angles;
## --thick: width of the pieces against their length (chunky chibi legs).

const SLICE := preload("res://tools/art/slice_ai_sheet.gd")
const PREPARE := preload("res://tools/art/prepare_ai_sprite.gd")
## Far leg: darker (in the shade of the body).
const FAR_SHADE := 0.72
## Share of the gait spent with the foot on the ground.
const STANCE := 0.42


## Width factor of the pieces (see --thick).
static var _thick := 1.0


class Piece:
	var image: Image
	## Joint at the top (hip or knee), in piece pixels.
	var top: Vector2
	## Thigh: the knee; shin: the sole (lowest point of the boot).
	var bottom: Vector2


func _initialize() -> void:
	var opts := {"upper": "", "parts": "", "frames": "8", "out": "", "leg": "0.62", "hip-in": "0.08",
		"spread": "0.26", "swing": "34", "knee": "95", "thick": "1.6"}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2 and opts.has(kv[0]):
			opts[kv[0]] = kv[1]
	if opts.upper == "" or opts.parts == "" or opts.out == "":
		printerr("usage: -- --upper=<strip> --parts=<sheet> --out=<strip> [--frames=8]")
		quit(1)
		return
	var count := int(opts.frames)
	var upper := Image.load_from_file(opts.upper)
	upper.convert(Image.FORMAT_RGBA8)
	PREPARE._remove_background(upper, 0.72)
	SLICE._remove_enclosed_white(upper)
	var bodies := SLICE._split_by_islands(upper, count)
	if bodies.size() != count:
		printerr("could not find %d upper bodies" % count)
		quit(1)
		return
	var pieces := _load_parts(opts.parts)
	if pieces.is_empty():
		quit(1)
		return
	var thigh: Piece = pieces[0]
	var shin: Piece = pieces[1]
	# Sizes from the first body: its height from the hair to the shorts' hem.
	var used0 := bodies[0].get_used_rect()
	var body_h := float(used0.size.y)
	var leg_len := body_h * float(opts.leg)
	var chain := thigh.top.distance_to(thigh.bottom) + shin.top.distance_to(shin.bottom)
	var scale := leg_len / chain
	_thick = float(opts.thick)
	var cell := Vector2i(roundi(body_h * 1.6), roundi(body_h * 2.0))
	var strip := Image.create(cell.x * count, cell.y, false, Image.FORMAT_RGBA8)
	var ground := cell.y - roundi(body_h * 0.1)
	for i in count:
		var body := bodies[i]
		var used := body.get_used_rect()
		var hem := _hem(body, used)
		var hip := Vector2(hem.x, used.end.y - body_h * float(opts["hip-in"]))
		var width := _hem_width(body, used)
		var near_hip := hip + Vector2(-width * float(opts.spread) * 0.5, 0.0)
		var far_hip := hip + Vector2(width * float(opts.spread) * 0.5, -body_h * 0.02)
		var phase := float(i) / count
		var near := _leg_pose(phase, float(opts.swing), float(opts.knee))
		var far := _leg_pose(fmod(phase + 0.5, 1.0), float(opts.swing), float(opts.knee))
		# Lowest sole on the ground: the body rides on the legs (natural bob).
		var near_sole := _sole(near_hip, near, thigh, shin, scale)
		var far_sole := _sole(far_hip, far, thigh, shin, scale)
		var lift := ground - maxf(near_sole.y, far_sole.y)
		var frame := Image.create(cell.x, cell.y, false, Image.FORMAT_RGBA8)
		var local := Vector2(cell.x * 0.5 - hip.x, lift)
		_draw_leg(frame, far_hip + local, far, thigh, shin, scale, FAR_SHADE)
		_draw_leg(frame, near_hip + local, near, thigh, shin, scale, 1.0)
		frame.blend_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i(local.round()))
		strip.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(cell.x * i, 0))
	strip.save_png(opts.out)
	print("baked %d frames into %s" % [count, opts.out])
	quit(0)


## Hip and knee angles (degrees; hip > 0 = thigh forward, knee >= 0 = shin folded back)
## at `phase` (0 = heel strike, foot forward).
static func _leg_pose(phase: float, swing: float, knee_max: float) -> Vector2:
	if phase < STANCE:
		# Stance: the foot pushes the body forward, the thigh goes from front to back.
		var t := phase / STANCE
		return Vector2(lerpf(swing, -swing * 0.8, t), 12.0 * sin(PI * t))
	# Swing: the leg comes back through, the knee folds high then reaches forward.
	var s := (phase - STANCE) / (1.0 - STANCE)
	var hip := lerpf(-swing * 0.8, swing, 0.5 - 0.5 * cos(PI * s))
	var knee := knee_max * sin(PI * minf(s * 1.15, 1.0))
	return Vector2(hip, knee)


## Downward direction turned forward (+x, the art faces right) by `deg` degrees.
static func _dir(deg: float) -> Vector2:
	var r := deg_to_rad(deg)
	return Vector2(sin(r), cos(r))


static func _knee(hip: Vector2, pose: Vector2, thigh: Piece, scale: float) -> Vector2:
	return hip + _dir(pose.x) * thigh.top.distance_to(thigh.bottom) * scale


static func _sole(hip: Vector2, pose: Vector2, thigh: Piece, shin: Piece, scale: float) -> Vector2:
	var knee := _knee(hip, pose, thigh, scale)
	return knee + _rotated((shin.bottom - shin.top) * Vector2(_thick, 1.0), pose.x - pose.y) * scale


## A piece vector (drawn hanging down) turned by `deg` (forward > 0).
static func _rotated(v: Vector2, deg: float) -> Vector2:
	return v.rotated(-deg_to_rad(deg))


static func _draw_leg(frame: Image, hip: Vector2, pose: Vector2, thigh: Piece, shin: Piece, scale: float,
		shade: float) -> void:
	var knee := _knee(hip, pose, thigh, scale)
	# The shin first: the thigh's knee covers its top.
	_blit_turned(frame, shin, knee, pose.x - pose.y, scale, shade)
	_blit_turned(frame, thigh, hip, pose.x, scale, shade)


## Draws `piece` with its top joint on `at`, turned by `deg` from its drawn (hanging)
## orientation, scaled; bilinear sampling, alpha blended.
static func _blit_turned(frame: Image, piece: Piece, at: Vector2, deg: float, scale: float, shade: float) -> void:
	var src := piece.image
	var angle := -deg_to_rad(deg)
	var corners: Array[Vector2] = []
	for c: Vector2 in [Vector2.ZERO, Vector2(src.get_width(), 0), Vector2(0, src.get_height()), Vector2(src.get_size())]:
		corners.append(at + ((c - piece.top) * Vector2(scale * _thick, scale)).rotated(angle))
	var lo := corners[0]
	var hi := corners[0]
	for c in corners:
		lo = lo.min(c)
		hi = hi.max(c)
	for y in range(maxi(0, floori(lo.y)), mini(frame.get_height(), ceili(hi.y) + 1)):
		for x in range(maxi(0, floori(lo.x)), mini(frame.get_width(), ceili(hi.x) + 1)):
			var p := (Vector2(x, y) - at).rotated(-angle) / Vector2(scale * _thick, scale) + piece.top
			if p.x < 0.0 or p.y < 0.0 or p.x > src.get_width() - 1 or p.y > src.get_height() - 1:
				continue
			var c := _bilinear(src, p)
			if c.a <= 0.01:
				continue
			c = Color(c.r * shade, c.g * shade, c.b * shade, c.a)
			frame.set_pixel(x, y, frame.get_pixel(x, y).blend(c))


static func _bilinear(img: Image, p: Vector2) -> Color:
	var x0 := floori(p.x)
	var y0 := floori(p.y)
	var x1 := mini(x0 + 1, img.get_width() - 1)
	var y1 := mini(y0 + 1, img.get_height() - 1)
	var fx := p.x - x0
	var fy := p.y - y0
	var top := img.get_pixel(x0, y0).lerp(img.get_pixel(x1, y0), fx)
	var bottom := img.get_pixel(x0, y1).lerp(img.get_pixel(x1, y1), fx)
	return top.lerp(bottom, fy)


## The thigh (left) and the shin with its boot (right) of a parts sheet, with their joints.
static func _load_parts(path: String) -> Array[Piece]:
	var sheet := Image.load_from_file(path)
	if sheet == null:
		printerr("cannot read " + path)
		return []
	sheet.convert(Image.FORMAT_RGBA8)
	PREPARE._remove_background(sheet, 0.72)
	var parts := SLICE._split_by_islands(sheet, 2)
	if parts.size() != 2:
		printerr("expected two pieces (thigh, shin) in " + path)
		return []
	var result: Array[Piece] = []
	for k in 2:
		var image := parts[k]
		var used := image.get_used_rect()
		image = image.get_region(used)
		var piece := Piece.new()
		piece.image = image
		var h := image.get_height()
		# Joints inside the rounded ends (a bit in from the edge, centered on the band).
		piece.top = Vector2(_band_center(image, roundi(h * 0.1)), h * 0.1)
		if k == 0:
			piece.bottom = Vector2(_band_center(image, roundi(h * 0.9)), h * 0.9)
		else:
			piece.bottom = Vector2(_band_center(image, h - 3), h - 1.0)
		result.append(piece)
	return result


## Middle x of the opaque pixels on row `y`.
static func _band_center(img: Image, y: int) -> float:
	var first := -1
	var last := -1
	for x in img.get_width():
		if img.get_pixel(x, clampi(y, 0, img.get_height() - 1)).a > 0.5:
			if first < 0:
				first = x
			last = x
	return (first + last) * 0.5 if first >= 0 else img.get_width() * 0.5


## Middle of the shorts' hem (bottom rows of the upper body).
static func _hem(body: Image, used: Rect2i) -> Vector2:
	return Vector2(_band_center(body, used.end.y - 4), used.end.y)


static func _hem_width(body: Image, used: Rect2i) -> float:
	var y := used.end.y - 6
	var first := -1
	var last := -1
	for x in body.get_width():
		if body.get_pixel(x, y).a > 0.5:
			if first < 0:
				first = x
			last = x
	return float(last - first) if first >= 0 else used.size.x * 0.5
