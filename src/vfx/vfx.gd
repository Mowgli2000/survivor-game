class_name Vfx
extends Node2D
## Short-lived combat effects (slashes, beams, explosions, sparks, lightning),
## stored in flat arrays and drawn by a single canvas item with additive
## blending: overlapping effects add up into a neon glow.
## Also the feedback hub: big effects request a camera shake.

signal shake_requested(amount: float)

enum Kind { SLASH, BEAM, EXPLOSION, HIT, LIGHTNING, WARN_CIRCLE, WARN_LINE }

const CAPACITY := 384

var _kind := PackedInt32Array()
var _a := PackedVector2Array()       # center / start
var _b := PackedVector2Array()       # direction / end
var _size := PackedFloat32Array()    # radius / width
var _extra := PackedFloat32Array()   # half angle / random seed
var _life := PackedFloat32Array()
var _max_life := PackedFloat32Array()
var _color := PackedColorArray()
var _count: int = 0
var _drawn: bool = false
var _seed: int = 0


func _init() -> void:
	z_index = 5
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	_kind.resize(CAPACITY)
	_a.resize(CAPACITY)
	_b.resize(CAPACITY)
	_size.resize(CAPACITY)
	_extra.resize(CAPACITY)
	_life.resize(CAPACITY)
	_max_life.resize(CAPACITY)
	_color.resize(CAPACITY)


func active_count() -> int:
	return _count


func slash(center: Vector2, angle: float, radius: float, half_angle: float, color: Color) -> void:
	_add(Kind.SLASH, center, Vector2.from_angle(angle), radius, half_angle, color, 0.16)


func beam(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	_add(Kind.BEAM, from, to, width, 0.0, color, 0.14)


func explosion(center: Vector2, radius: float, color: Color, shake: bool) -> void:
	_add(Kind.EXPLOSION, center, Vector2.ZERO, radius, 0.0, color, 0.3)
	if shake:
		shake_requested.emit(clampf(radius / 400.0, 0.1, 0.4))


func hit(pos: Vector2, color: Color = Color(1, 1, 1, 0.8)) -> void:
	_add(Kind.HIT, pos, Vector2.ZERO, 12.0, _next_seed(), color, 0.1)


func lightning(from: Vector2, to: Vector2, color: Color) -> void:
	_add(Kind.LIGHTNING, from, to, 3.0, _next_seed(), color, 0.18)


## Boss telegraph: a ring that fills up during `life` seconds.
func warning_circle(center: Vector2, radius: float, color: Color, life: float) -> void:
	_add(Kind.WARN_CIRCLE, center, Vector2.ZERO, radius, 0.0, color, life)


## Boss telegraph: a band showing a dash path or an aimed shot.
func warning_line(from: Vector2, to: Vector2, width: float, color: Color, life: float) -> void:
	_add(Kind.WARN_LINE, from, to, width, 0.0, color, life)


func _add(kind: Kind, a: Vector2, b: Vector2, size: float, extra: float, color: Color, life: float) -> void:
	if _count >= CAPACITY:
		return  # Dropping a cosmetic effect is better than a frame spike.
	var i := _count
	_kind[i] = kind
	_a[i] = a
	_b[i] = b
	_size[i] = size
	_extra[i] = extra
	_life[i] = life
	_max_life[i] = life
	_color[i] = color
	_count += 1


func _next_seed() -> float:
	_seed = (_seed + 1) % 997
	return float(_seed)


func _process(delta: float) -> void:
	if _count == 0 and not _drawn:
		return
	for i in range(_count - 1, -1, -1):
		_life[i] -= delta
		if _life[i] <= 0.0:
			_remove(i)
	_drawn = _count > 0
	queue_redraw()


func _remove(i: int) -> void:
	var last := _count - 1
	_kind[i] = _kind[last]
	_a[i] = _a[last]
	_b[i] = _b[last]
	_size[i] = _size[last]
	_extra[i] = _extra[last]
	_life[i] = _life[last]
	_max_life[i] = _max_life[last]
	_color[i] = _color[last]
	_count = last


func _draw() -> void:
	for i in _count:
		var t := _life[i] / _max_life[i]  # 1 -> 0
		var color := _color[i]
		match _kind[i]:
			Kind.SLASH:
				_draw_slash(_a[i], _b[i].angle(), _size[i], _extra[i], color, t)
			Kind.BEAM:
				_draw_beam(_a[i], _b[i], _size[i], color, t)
			Kind.EXPLOSION:
				_draw_explosion(_a[i], _size[i], color, t)
			Kind.HIT:
				_draw_hit(_a[i], _size[i], _extra[i], color, t)
			Kind.LIGHTNING:
				_draw_lightning(_a[i], _b[i], _extra[i], color, t)
			Kind.WARN_CIRCLE:
				draw_circle(_a[i], _size[i] * (1.0 - t), Color(color, 0.18))
				draw_arc(_a[i], _size[i], 0.0, TAU, 48, Color(color, 0.7), 3.0, true)
			Kind.WARN_LINE:
				draw_line(_a[i], _b[i], Color(color, 0.12 + 0.18 * (1.0 - t)), _size[i], true)
				draw_line(_a[i], _b[i], Color(color, 0.6), 2.0, true)


func _draw_slash(center: Vector2, angle: float, radius: float, half: float, color: Color, t: float) -> void:
	var r := radius * 0.82
	var width := 0.6 + 0.4 * t
	draw_arc(center, r, angle - half, angle + half, 28, Color(color, 0.18 * t), 26.0 * width, true)
	draw_arc(center, r, angle - half, angle + half, 28, Color(color, 0.55 * t), 11.0 * width, true)
	draw_arc(center, r, angle - half * 0.9, angle + half * 0.9, 28, Color(color.lerp(Color.WHITE, 0.6), t), 3.5, true)


func _draw_beam(from: Vector2, to: Vector2, width: float, color: Color, t: float) -> void:
	draw_line(from, to, Color(color, 0.2 * t), width * 3.0, true)
	draw_line(from, to, Color(color, 0.65 * t), width * 1.2, true)
	draw_line(from, to, Color(color.lerp(Color.WHITE, 0.7), t), maxf(width * 0.35, 2.0), true)


func _draw_explosion(center: Vector2, radius: float, color: Color, t: float) -> void:
	var r := radius * (0.35 + 0.65 * sqrt(1.0 - t))
	draw_circle(center, r, Color(color, 0.16 * t))
	draw_arc(center, r, 0.0, TAU, 40, Color(color, 0.85 * t), 2.0 + 6.0 * t, true)


func _draw_hit(pos: Vector2, size: float, noise_seed: float, color: Color, t: float) -> void:
	var length := size * (0.4 + 0.6 * (1.0 - t))
	for k in 4:
		var direction := Vector2.from_angle(noise_seed + k * TAU / 4.0)
		draw_line(pos + direction * 3.0, pos + direction * (3.0 + length), Color(color, t), 2.0, true)


func _draw_lightning(from: Vector2, to: Vector2, noise_seed: float, color: Color, t: float) -> void:
	const SEGMENTS := 6
	var points := PackedVector2Array()
	var normal := (to - from).orthogonal().normalized()
	var jitter := from.distance_to(to) * 0.18
	points.append(from)
	for k in range(1, SEGMENTS):
		var noise := fposmod(sin(noise_seed * 12.9898 + k * 78.233) * 43758.5453, 1.0) - 0.5
		points.append(from.lerp(to, float(k) / SEGMENTS) + normal * noise * jitter)
	points.append(to)
	draw_polyline(points, Color(color, 0.3 * t), 9.0, true)
	draw_polyline(points, Color(color.lerp(Color.WHITE, 0.5), t), 2.5, true)
