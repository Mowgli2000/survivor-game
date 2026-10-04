class_name Vfx
extends Node2D
## Short-lived combat effects (slashes, beams, explosions, sparks, lightning),
## stored in flat arrays and drawn by a single canvas item. Flat manga style
## (art bible): black ink outline, flat color, light core; normal blending.
## Also the feedback hub: big effects request a camera shake.

signal shake_requested(amount: float)

enum Kind { SLASH, BEAM, EXPLOSION, HIT, LIGHTNING, WARN_CIRCLE, WARN_LINE, PORTAL }

const CAPACITY := 384
## Outline color of every effect (the art's black line).
const INK := Color(0.05, 0.04, 0.1)
## Gate color: monsters step out of violet portals (art bible).
const PORTAL_COLOR := Color(0.64, 0.35, 1.0)
const SLASH_LIFE := 0.2
const SLASH_LIFE_SLOW := 0.28
## Share of a slash's life spent sweeping across its arc.
const SWEEP := 0.45
const SLASH_POINTS := 18

var _kind := PackedInt32Array()
var _a := PackedVector2Array()       # center / start
var _b := PackedVector2Array()       # direction / end
var _size := PackedFloat32Array()    # radius / width
var _extra := PackedFloat32Array()   # half angle / random seed
var _life := PackedFloat32Array()
var _max_life := PackedFloat32Array()
var _color := PackedColorArray()
var _style := PackedInt32Array()     # slash style (WeaponData.SlashStyle)
var _count: int = 0
var _drawn: bool = false
var _seed: int = 0
# Reused polygon buffers for slashes (no allocation per effect).
var _poly := PackedVector2Array()
var _core := PackedVector2Array()
var _outline := PackedVector2Array()
var _strip_indices := PackedInt32Array()
var _band_colors := PackedColorArray()
var _tri_colors := PackedColorArray()
var _no_uvs := PackedVector2Array()


func _init() -> void:
	z_index = 5
	_kind.resize(CAPACITY)
	_a.resize(CAPACITY)
	_b.resize(CAPACITY)
	_size.resize(CAPACITY)
	_extra.resize(CAPACITY)
	_life.resize(CAPACITY)
	_max_life.resize(CAPACITY)
	_color.resize(CAPACITY)
	_style.resize(CAPACITY)


func active_count() -> int:
	return _count


## Melee hit drawn in the weapon's style (WeaponData.SlashStyle): the blade
## sweeps across the arc, then the trail thins and fades.
func slash(center: Vector2, angle: float, radius: float, half_angle: float, color: Color,
		style: int = 0) -> void:
	var life := SLASH_LIFE_SLOW if style == WeaponData.SlashStyle.HEAVY or style == WeaponData.SlashStyle.SMASH 		else SLASH_LIFE
	_add(Kind.SLASH, center, Vector2.from_angle(angle), radius, half_angle, color, life, style)


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


## Spawn gate: a violet portal that opens and closes where a monster appears
## (used for boss entrances, with a camera shake).
func portal(center: Vector2, radius: float, boss: bool = false) -> void:
	_add(Kind.PORTAL, center, Vector2.ZERO, radius, 0.0, PORTAL_COLOR, 0.9 if boss else 0.4)
	if boss:
		shake_requested.emit(0.5)


## Boss telegraph: a ring that fills up during `life` seconds.
func warning_circle(center: Vector2, radius: float, color: Color, life: float) -> void:
	_add(Kind.WARN_CIRCLE, center, Vector2.ZERO, radius, 0.0, color, life)


## Boss telegraph: a band showing a dash path or an aimed shot.
func warning_line(from: Vector2, to: Vector2, width: float, color: Color, life: float) -> void:
	_add(Kind.WARN_LINE, from, to, width, 0.0, color, life)


func _add(kind: Kind, a: Vector2, b: Vector2, size: float, extra: float, color: Color, life: float,
		style: int = 0) -> void:
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
	_style[i] = style
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
	_style[i] = _style[last]
	_count = last


func _draw() -> void:
	for i in _count:
		var t := _life[i] / _max_life[i]  # 1 -> 0
		var color := _color[i]
		match _kind[i]:
			Kind.SLASH:
				_draw_slash(_a[i], _b[i].angle(), _size[i], _extra[i], color, t, _style[i])
			Kind.BEAM:
				_draw_beam(_a[i], _b[i], _size[i], color, t)
			Kind.EXPLOSION:
				_draw_explosion(_a[i], _size[i], color, t)
			Kind.HIT:
				_draw_hit(_a[i], _size[i], _extra[i], color, t)
			Kind.LIGHTNING:
				_draw_lightning(_a[i], _b[i], _extra[i], color, t)
			Kind.WARN_CIRCLE:
				draw_circle(_a[i], _size[i] * (1.0 - t), Color(color, 0.25))
				draw_arc(_a[i], _size[i], 0.0, TAU, 48, Color(INK, 0.6), 6.0, true)
				draw_arc(_a[i], _size[i], 0.0, TAU, 48, Color(color, 0.85), 3.0, true)
			Kind.PORTAL:
				_draw_portal(_a[i], _size[i], color, t)
			Kind.WARN_LINE:
				draw_line(_a[i], _b[i], Color(color, 0.15 + 0.2 * (1.0 - t)), _size[i], true)
				draw_line(_a[i], _b[i], Color(color, 0.8), 2.0, true)


func _draw_slash(center: Vector2, angle: float, radius: float, half: float, color: Color, t: float,
		style: int) -> void:
	var age := 1.0 - t
	var head := clampf(age / SWEEP, 0.0, 1.0)            # how far the blade has swept
	var fade := clampf(t / (1.0 - SWEEP), 0.0, 1.0)      # trail thins once the sweep is done
	var light := color.lerp(Color.WHITE, 0.75)
	match style:
		WeaponData.SlashStyle.THRUST:
			_draw_thrust(center, angle, radius, color, light, head, fade)
			return
		WeaponData.SlashStyle.THIN:
			_draw_crescent(center, angle, radius, half, radius * 0.07, color, light, head, fade, 0.6)
			_draw_crescent(center, angle - half * 0.12, radius * 0.86, half * 0.8, radius * 0.035,
				Color(color, 0.5), light, head, fade * 0.6, 0.0)
		WeaponData.SlashStyle.HEAVY:
			_draw_crescent(center, angle, radius, half, radius * 0.3, color.darkened(0.15), light, head, fade, 0.3)
			for k in 3:
				var a := angle - half + half * 2.0 * head - 0.25 * (k + 1)
				var r := radius * (1.04 + 0.05 * k)
				draw_arc(center, r, a - 0.18, a, 6, Color(light, 0.7 * fade), 3.0)
		WeaponData.SlashStyle.SMASH:
			_draw_crescent(center, angle, radius * 0.8, half, radius * 0.22, color, light, head, fade, 0.3)
			if age > SWEEP * 0.6:
				var impact := center + Vector2.from_angle(angle) * radius * 0.7
				var wave := radius * (0.25 + 0.45 * clampf((age - SWEEP * 0.6) / 0.5, 0.0, 1.0))
				draw_arc(impact, wave, 0.0, TAU, 28, Color(INK, 0.8 * fade), 9.0)
				draw_arc(impact, wave, 0.0, TAU, 28, Color(color, fade), 5.0)
				for k in 5:
					var d := Vector2.from_angle(angle + k * TAU / 5.0 + 0.4)
					draw_line(impact + d * wave * 0.2, impact + d * wave * 0.85, Color(INK, 0.8 * fade), 4.0)
		WeaponData.SlashStyle.FLAME:
			_draw_crescent(center, angle, radius, half, radius * 0.2, color, Color(1.0, 0.95, 0.6), head, fade, 0.4)
			_draw_flames(center, angle, radius, half, head, fade, age)
		WeaponData.SlashStyle.RUNIC:
			_draw_crescent(center, angle, radius, half, radius * 0.18, color, light, head, fade, 0.4)
			_draw_arc_lightning(center, angle, radius * 0.88, half, head, fade, age)
		_:
			_draw_crescent(center, angle, radius, half, radius * 0.2, color, light, head, fade, 0.4)


## Tapered crescent from angle - half to the blade's current position (`head`),
## thickest in the middle: ink outline, flat color, light core along the edge.
func _draw_crescent(center: Vector2, angle: float, radius: float, half: float, thickness: float,
		color: Color, light: Color, head: float, fade: float, core: float) -> void:
	var span := half * 2.0 * head
	# A sliver too thin to triangulate is invisible anyway.
	if fade <= 0.0 or span * radius < 4.0:
		return
	var from := angle - half
	var width := thickness * (0.35 + 0.65 * fade)
	_poly.resize(SLASH_POINTS * 2)
	_core.resize(SLASH_POINTS * 2)
	for k in SLASH_POINTS:
		var u := float(k) / (SLASH_POINTS - 1)
		var a := from + span * u
		# Thin tail, thick body, sharp leading tip.
		var w := width * pow(sin(PI * clampf(u * 0.92 + 0.04, 0.0, 1.0)), 0.6)
		var dir := Vector2.from_angle(a)
		_poly[k] = center + dir * radius
		_poly[SLASH_POINTS * 2 - 1 - k] = center + dir * (radius - w)
		_core[k] = center + dir * (radius - w * 0.08)
		_core[SLASH_POINTS * 2 - 1 - k] = center + dir * (radius - w * core)
	_outline.resize(SLASH_POINTS * 2 + 1)
	for k in SLASH_POINTS * 2:
		_outline[k] = _poly[k]
	_outline[SLASH_POINTS * 2] = _poly[0]
	draw_polyline(_outline, Color(INK, 0.85 * fade), 5.0)
	_draw_band(_poly, Color(color, 0.95 * fade))
	if core > 0.0:
		_draw_band(_core, Color(light, fade))


## One filled triangle from _poly[0..2]. draw_primitive does not triangulate,
## so a triangle that flattens at the end of its animation never fails.
func _draw_triangle(color: Color) -> void:
	_tri_colors.resize(3)
	_tri_colors.fill(color)
	draw_primitive(_poly, _tri_colors, _no_uvs)


## Fills a band given as SLASH_POINTS outer points then the inner ones reversed,
## as a triangle strip: a crescent is concave, so a polygon fill could fail to
## triangulate; the strip never does.
func _draw_band(band: PackedVector2Array, color: Color) -> void:
	if _strip_indices.is_empty():
		for k in SLASH_POINTS - 1:
			var o0 := k
			var o1 := k + 1
			var i0 := SLASH_POINTS * 2 - 1 - k
			var i1 := SLASH_POINTS * 2 - 2 - k
			_strip_indices.append_array([o0, o1, i0, o1, i1, i0])
	_band_colors.resize(band.size())
	_band_colors.fill(color)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _strip_indices, band, _band_colors)


## Thrust (spear, rapier): a long narrow spike shooting out, with speed lines.
func _draw_thrust(center: Vector2, angle: float, radius: float, color: Color, light: Color,
		head: float, fade: float) -> void:
	var dir := Vector2.from_angle(angle)
	var side := dir.orthogonal()
	var base := center + dir * radius * 0.15
	var tip := center + dir * radius * (0.35 + 0.65 * head)
	var w := radius * 0.11 * (0.4 + 0.6 * fade)
	_poly.resize(3)
	_poly[0] = base + side * w
	_poly[1] = tip
	_poly[2] = base - side * w
	_outline.resize(4)
	_outline[0] = _poly[0]
	_outline[1] = _poly[1]
	_outline[2] = _poly[2]
	_outline[3] = _poly[0]
	draw_polyline(_outline, Color(INK, 0.85 * fade), 5.0)
	_draw_triangle(Color(color, 0.95 * fade))
	draw_line(base, tip.lerp(base, 0.1), Color(light, fade), maxf(w * 0.4, 2.0))
	for k in [-1.0, 1.0]:
		var offset: Vector2 = side * w * 2.2 * k
		draw_line(base.lerp(tip, 0.25) + offset, base.lerp(tip, 0.8) + offset, Color(light, 0.6 * fade), 2.0)


## Flame tongues licking out of a crescent's outer edge (flaming sword).
func _draw_flames(center: Vector2, angle: float, radius: float, half: float, head: float, fade: float,
		age: float) -> void:
	var count := maxi(3, int(half * 2.0 / 0.22))
	for k in count:
		var u := (k + 0.5) / count
		if u > head:
			break
		var a := angle - half + half * 2.0 * u
		var dir := Vector2.from_angle(a)
		var flicker := 0.7 + 0.3 * sin(age * 40.0 + k * 2.3)
		var length := radius * 0.16 * flicker * sin(PI * u) * fade
		var root := center + dir * radius * 0.97
		_poly.resize(3)
		_poly[0] = root + dir.orthogonal() * radius * 0.04
		_poly[1] = root + dir * length + dir.orthogonal() * -radius * 0.05
		_poly[2] = root - dir.orthogonal() * radius * 0.04
		_draw_triangle(Color(1.0, 0.75, 0.2, fade))


## Zigzag spark running along a crescent (runic blade).
func _draw_arc_lightning(center: Vector2, angle: float, radius: float, half: float, head: float,
		fade: float, age: float) -> void:
	_outline.resize(SLASH_POINTS)
	for k in SLASH_POINTS:
		var u := float(k) / (SLASH_POINTS - 1) * head
		var a := angle - half + half * 2.0 * u
		var jitter := (fposmod(sin(k * 12.9898 + floor(age * 30.0)) * 43758.5453, 1.0) - 0.5) * radius * 0.12
		_outline[k] = center + Vector2.from_angle(a) * (radius + jitter)
	draw_polyline(_outline, Color(INK, 0.7 * fade), 5.0)
	draw_polyline(_outline, Color(0.85, 1.0, 1.0, fade), 2.5)


func _draw_beam(from: Vector2, to: Vector2, width: float, color: Color, t: float) -> void:
	draw_line(from, to, Color(INK, 0.85 * t), width * 1.2 + 5.0, true)
	draw_line(from, to, Color(color, 0.95 * t), width * 1.2, true)
	draw_line(from, to, Color(color.lerp(Color.WHITE, 0.7), t), maxf(width * 0.35, 2.0), true)


func _draw_explosion(center: Vector2, radius: float, color: Color, t: float) -> void:
	var r := radius * (0.35 + 0.65 * sqrt(1.0 - t))
	# One per enemy death: cheap draws only (no antialiasing, few segments).
	draw_circle(center, r, Color(color, 0.3 * t))
	draw_arc(center, r, 0.0, TAU, 24, Color(INK, 0.8 * t), 4.0 + 6.0 * t)
	draw_arc(center, r, 0.0, TAU, 24, Color(color, t), 2.0 + 4.0 * t)


func _draw_hit(pos: Vector2, size: float, noise_seed: float, color: Color, t: float) -> void:
	var length := size * (0.4 + 0.6 * (1.0 - t))
	for k in 4:
		var direction := Vector2.from_angle(noise_seed + k * TAU / 4.0)
		draw_line(pos + direction * 3.0, pos + direction * (3.0 + length), Color(color, t), 2.5)


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
	draw_polyline(points, Color(INK, 0.8 * t), 7.0, true)
	draw_polyline(points, Color(color, t), 4.0, true)


func _draw_portal(center: Vector2, radius: float, color: Color, t: float) -> void:
	# Opens then closes (0 -> 1 -> 0 over its life).
	var r := radius * sin(PI * (1.0 - t))
	draw_circle(center, r, Color(INK, 0.6))
	draw_arc(center, r, 0.0, TAU, 16, color, 4.0)
