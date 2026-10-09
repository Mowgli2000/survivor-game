class_name PortalFx
extends Control
## The last seal's menace: red lightning striking out of the portal, drawn by code in the same flat
## manga style as the portal (dark outline, red body, white core, no glow). Real lightning: a bolt is
## a jagged path (midpoint displacement) with a few forks; it shoots out in a fraction of a second
## (the tip races along the path), flickers while it holds, then vanishes. Bolts of very different
## sizes appear at random, from anywhere inside the opening or on its rim, with a crack sound each.
## Display only. `intensity` (0..1) turns the effect on and off (the seal pointed).

## Bolts alive at once, at most.
const MAX_BOLTS := 5
## Seconds between two new bolts.
const SPAWN_GAP := Vector2(0.12, 0.5)
## Bolt length as a share of the opening's half height (most are small, a few are big).
const LENGTH_MIN := 0.12
const LENGTH_SPAN := 0.85
const SEGMENT_DEPTH := 4
const OUTLINE := Color(0.25, 0.0, 0.04)
const BODY := Color(1.0, 0.16, 0.2)
const CORE := Color(1.0, 0.92, 0.9)

## 0..1: how present the effect is.
var intensity: float = 0.0:
	set(value):
		intensity = value
		visible = value > 0.01
		if not visible:
			_bolts.clear()
## Center of the opening and its half size in px (see place).
var center: Vector2 = Vector2.ZERO
var half_size: Vector2 = Vector2(100.0, 200.0)

## Each bolt: {points: PackedVector2Array, forks: Array[PackedVector2Array], fork_at: Array[float],
## age, grow, hold, fade, width}
var _bolts: Array[Dictionary] = []
var _next_spawn: float = 0.3
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_rng.seed = 11


## Puts the effect around the opening (the screen layout calls it when the picture is laid out).
func place(p_center: Vector2, p_half_size: Vector2) -> void:
	center = p_center
	half_size = p_half_size
	_bolts.clear()


func bolt_count() -> int:
	return _bolts.size()


## A jagged path from `from` to `to`: midpoint displacement, `depth` halvings.
func jagged(from: Vector2, to: Vector2, depth: int, amplitude: float) -> PackedVector2Array:
	var points := PackedVector2Array([from, to])
	var offset := amplitude
	for level in depth:
		var next := PackedVector2Array()
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			var normal := (b - a).orthogonal().normalized()
			next.append(a)
			next.append((a + b) * 0.5 + normal * _rng.randf_range(-offset, offset))
		next.append(points[points.size() - 1])
		points = next
		offset *= 0.55
	return points


## A new bolt: starts inside the opening or on its rim, goes outward, with 0-3 forks.
func spawn_bolt() -> void:
	var angle := _rng.randf() * TAU
	var inside := _rng.randf() < 0.55
	var spread := 0.2 + 0.7 * _rng.randf() if inside else 0.98
	var from := center + Vector2(cos(angle) * half_size.x * spread, sin(angle) * half_size.y * spread * 0.95)
	var heading := angle + _rng.randf_range(-0.6, 0.6)
	var size_class := LENGTH_MIN + LENGTH_SPAN * pow(_rng.randf(), 1.8)
	var length := half_size.y * size_class
	var to := from + Vector2(cos(heading) * 0.75, sin(heading)) * length
	var points := jagged(from, to, SEGMENT_DEPTH, length * 0.16)
	var forks: Array[PackedVector2Array] = []
	var fork_at: Array[float] = []
	for k in _rng.randi_range(0, 3 if size_class > 0.3 else 1):
		var fraction := _rng.randf_range(0.2, 0.8)
		var index := clampi(roundi(fraction * (points.size() - 1)), 1, points.size() - 2)
		var branch_dir := (to - from).normalized().rotated(_rng.randf_range(0.4, 0.9) * (1.0 if _rng.randf() < 0.5 else -1.0))
		var tip := points[index] + branch_dir * length * _rng.randf_range(0.25, 0.45)
		forks.append(jagged(points[index], tip, 3, length * 0.07))
		fork_at.append(float(index) / (points.size() - 1))
	var quick := size_class < 0.35
	_bolts.append({
		"points": points, "forks": forks, "fork_at": fork_at, "age": 0.0,
		"grow": _rng.randf_range(0.05, 0.09) if quick else _rng.randf_range(0.09, 0.17),
		"hold": _rng.randf_range(0.08, 0.2), "fade": _rng.randf_range(0.14, 0.26),
		"width": lerpf(2.2, 5.5, clampf(size_class, 0.0, 1.0)), "size": size_class})
	Audio.play(Sounds.LIGHTNING_ZAP[_rng.randi() % Sounds.LIGHTNING_ZAP.size()],
		-14.0 + 6.0 * clampf(size_class, 0.0, 1.0), 0.12)


func _process(delta: float) -> void:
	if not visible:
		return
	if not UiFx.reduce_motion:
		_next_spawn -= delta
		if _next_spawn <= 0.0 and _bolts.size() < MAX_BOLTS:
			spawn_bolt()
			_next_spawn = _rng.randf_range(SPAWN_GAP.x, SPAWN_GAP.y)
	var i := _bolts.size() - 1
	while i >= 0:
		var bolt := _bolts[i]
		bolt["age"] = float(bolt["age"]) + delta
		if float(bolt["age"]) > float(bolt["grow"]) + float(bolt["hold"]) + float(bolt["fade"]):
			_bolts.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	for bolt in _bolts:
		_draw_bolt(bolt)


func _draw_bolt(bolt: Dictionary) -> void:
	var age: float = bolt["age"]
	var grow: float = bolt["grow"]
	var hold: float = bolt["hold"]
	var fade: float = bolt["fade"]
	var reveal := 1.0
	var strength := 1.0
	if age < grow:
		# The tip races out: fast at first.
		reveal = 1.0 - pow(1.0 - age / grow, 2.5)
	elif age < grow + hold:
		# Fully out: it flickers, bright / dim / bright, like a real strike.
		strength = 1.0 if int((age - grow) / 0.035) % 2 == 0 else 0.55
	else:
		strength = 1.0 - (age - grow - hold) / fade
		reveal = 1.0
	var width: float = float(bolt["width"]) * intensity
	var points: PackedVector2Array = bolt["points"]
	_polyline(points, reveal, width, strength)
	var forks: Array = bolt["forks"]
	var fork_at: Array = bolt["fork_at"]
	for k in forks.size():
		# A fork starts when the main bolt's tip has passed its junction.
		var local := clampf((reveal - float(fork_at[k])) / 0.35, 0.0, 1.0)
		if local > 0.0:
			_polyline(forks[k], local, width * 0.6, strength)
	# A small flash at the head of a growing bolt.
	if age < grow:
		var head := points[clampi(roundi(reveal * (points.size() - 1)), 0, points.size() - 1)]
		draw_circle(head, width * 1.6, Color(CORE, 0.9 * strength))


## `points` drawn up to `reveal` (0..1) of their length, in three flat layers.
func _polyline(points: PackedVector2Array, reveal: float, width: float, strength: float) -> void:
	var count := clampi(ceili(reveal * (points.size() - 1)) + 1, 2, points.size())
	var shown := points.slice(0, count)
	if reveal < 1.0 and shown.size() >= 2:
		# The last point slides toward the next so the tip grows smoothly.
		var partial := reveal * (points.size() - 1) - (count - 2)
		shown[count - 1] = points[count - 2].lerp(points[count - 1], clampf(partial, 0.0, 1.0))
	draw_polyline(shown, Color(OUTLINE, strength), width * 2.4, true)
	draw_polyline(shown, Color(BODY, strength), width * 1.3, true)
	draw_polyline(shown, Color(CORE, strength), maxf(width * 0.45, 1.0), true)
