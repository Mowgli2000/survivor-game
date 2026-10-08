class_name VfxArt
extends RefCounted
## How the combat effects look ("premium" pass, 2026-10-09; Vfx keeps the data and the
## timing). Two layers: the body (normal blending: feathered blade trails, smoke) and the
## glow (additive blending: auras, sparks, flashes, shock rings), built from baked soft
## textures and vertex-colored strips instead of hard circles and outlines.
## Every function draws on the CanvasItem it is given and allocates nothing per call.

## Samples along a blade trail, and vertices across its thickness.
const POINTS := 26
const ROWS := 4
## Blade trail cross-section: [offset from the outer edge (share of the thickness), color
## key]. Outer edge white-hot, then the light tint, the weapon color, a feathered inner edge.
const ROW_OFFSETS: Array[float] = [0.0, 0.12, 0.45, 1.0]
const SPARKS := 7
const EMBERS := 8
const INK := Color(0.05, 0.04, 0.1)

static var _glow_cache: ImageTexture
static var _ring_cache: ImageTexture

var _verts := PackedVector2Array()
var _cols := PackedColorArray()
var _indices := PackedInt32Array()
var _line := PackedVector2Array()
var _spike_verts := PackedVector2Array()
var _spike_cols := PackedColorArray()
var _spike_tris := PackedInt32Array([0, 1, 3, 1, 2, 3])


# --- Baked textures ------------------------------------------------------------

## Soft round glow: white, alpha 1 at the center falling smoothly to 0 at the edge.
static func glow_texture() -> ImageTexture:
	if _glow_cache != null:
		return _glow_cache
	const SIZE := 128
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var half := SIZE * 0.5
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length() / half
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, pow(clampf(1.0 - d, 0.0, 1.0), 2.2)))
	_glow_cache = ImageTexture.create_from_image(image)
	return _glow_cache


## Thin soft ring peaking at 80 % of the radius (shock waves).
static func ring_texture() -> ImageTexture:
	if _ring_cache != null:
		return _ring_cache
	const SIZE := 128
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var half := SIZE * 0.5
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length() / half
			var edge := exp(-pow((d - 0.8) / 0.08, 2.0)) * (1.0 - smoothstep(0.92, 1.0, d))
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, edge))
	_ring_cache = ImageTexture.create_from_image(image)
	return _ring_cache


static func glow(ci: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5 or color.a <= 0.01:
		return
	ci.draw_texture_rect(glow_texture(), Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)


## A ring whose bright line sits at `radius`.
static func ring(ci: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	var size := radius / 0.8
	if size < 1.0 or color.a <= 0.01:
		return
	ci.draw_texture_rect(ring_texture(), Rect2(at - Vector2(size, size), Vector2(size, size) * 2.0), false, color)


## Four thin rays (a flash's star).
static func star(ci: CanvasItem, at: Vector2, length: float, turn: float, color: Color, width: float = 2.0) -> void:
	if length < 1.0 or color.a <= 0.01:
		return
	for k in 4:
		var d := Vector2.from_angle(turn + k * PI * 0.5) * length
		ci.draw_line(at, at + d, color, width, true)


# --- Slash ---------------------------------------------------------------------

## Thickness of the blade trail, share of the reach, and how much of the arc it keeps
## behind the blade, by WeaponData.SlashStyle.
static func trail_thickness(style: int) -> float:
	match style:
		WeaponData.SlashStyle.THIN:
			return 0.07
		WeaponData.SlashStyle.HEAVY:
			return 0.3
		WeaponData.SlashStyle.SMASH:
			return 0.22
		WeaponData.SlashStyle.RUNIC:
			return 0.18
	return 0.26


static func trail_length(style: int) -> float:
	match style:
		WeaponData.SlashStyle.THIN:
			return 0.8
		WeaponData.SlashStyle.HEAVY:
			return 0.55
		WeaponData.SlashStyle.SMASH:
			return 0.5
		WeaponData.SlashStyle.FLAME:
			return 0.75
	return 0.68


## Body of a swing: a dark underlay for contrast, then the feathered trail.
func slash_body(ci: CanvasItem, center: Vector2, angle: float, radius: float, half: float, color: Color,
		style: int, head: float, fade: float, age: float, seed: float) -> void:
	var light := color.lerp(Color.WHITE, 0.75)
	if style == WeaponData.SlashStyle.THRUST:
		spike(ci, center, angle, radius, color, light, head, fade)
		return
	var reach := radius
	if style == WeaponData.SlashStyle.SMASH:
		reach = radius * 0.8
	var thickness := reach * trail_thickness(style)
	var tail := trail_length(style)
	var body := color
	if style == WeaponData.SlashStyle.HEAVY:
		body = color.darkened(0.15)
	elif style == WeaponData.SlashStyle.FLAME:
		body = color.lerp(Color(1.0, 0.55, 0.12), 0.5)
		light = Color(1.0, 0.95, 0.65)
	blade(ci, center, angle, reach, half, thickness * 1.35, Color(INK, 0.3), Color(INK, 0.3), Color(INK, 0.22),
		Color(INK, 0.0), head, fade, tail)
	blade(ci, center, angle, reach, half, thickness, Color.WHITE.lerp(light, 0.25), light, body, Color(body, 0.3),
		head, fade, tail)
	if style == WeaponData.SlashStyle.SMASH and age > 0.2:
		_dust(ci, center, angle, radius, age, fade, seed)


## Feathered crescent: ROWS vertices across the thickness at POINTS places from the
## tail (transparent) to the blade (opaque), thin tail, thick middle, sharp tip.
## `c0`..`c3`: colors from the outer edge to the inner one (alpha before the tail fade).
func blade(ci: CanvasItem, center: Vector2, angle: float, radius: float, half: float, thickness: float,
		c0: Color, c1: Color, c2: Color, c3: Color, head: float, fade: float, tail: float) -> void:
	var start := maxf(0.0, head - tail)
	if fade <= 0.01 or (head - start) * half * 2.0 * radius < 4.0:
		return
	_ensure_strip()
	var colors: Array[Color] = [c0, c1, c2, c3]
	for k in POINTS:
		var f := float(k) / (POINTS - 1)
		var a := angle - half + half * 2.0 * lerpf(start, head, f)
		var dir := Vector2.from_angle(a)
		var w := thickness * (0.2 + 0.8 * f) * (1.0 - smoothstep(0.86, 1.0, f) * 0.9) * (0.4 + 0.6 * fade)
		var alpha := pow(f, 0.85) * fade
		for j in ROWS:
			_verts[k * ROWS + j] = center + dir * (radius - w * ROW_OFFSETS[j])
			var c := colors[j]
			_cols[k * ROWS + j] = Color(c.r, c.g, c.b, c.a * alpha)
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), _indices, _verts, _cols)


func _ensure_strip() -> void:
	if not _indices.is_empty():
		return
	_verts.resize(POINTS * ROWS)
	_cols.resize(POINTS * ROWS)
	for k in POINTS - 1:
		for j in ROWS - 1:
			var a := k * ROWS + j
			var b := (k + 1) * ROWS + j
			_indices.append_array([a, b, a + 1, b, b + 1, a + 1])


## Additive layer of a swing: aura, glowing blade tip, flying sparks, the flash and shock
## ring of the impact, and each style's own touch (embers, arcs of lightning, ground wave).
func slash_glow(ci: CanvasItem, center: Vector2, angle: float, radius: float, half: float, color: Color,
		style: int, head: float, fade: float, age: float, seed: float) -> void:
	var light := color.lerp(Color.WHITE, 0.75)
	if style == WeaponData.SlashStyle.THRUST:
		_spike_glow(ci, center, angle, radius, color, light, head, fade, age)
		return
	var reach := radius * (0.8 if style == WeaponData.SlashStyle.SMASH else 1.0)
	var thickness := reach * trail_thickness(style)
	var tail := trail_length(style)
	var start := maxf(0.0, head - tail)
	var tip_angle := angle - half + half * 2.0 * head
	var dir := Vector2.from_angle(tip_angle)
	var tip := center + dir * reach
	var aura := color
	if style == WeaponData.SlashStyle.FLAME:
		aura = Color(1.0, 0.5, 0.12)
	# Wide soft aura along the trail: a strip feathered on both sides.
	blade(ci, center, angle, reach + thickness * 0.55, half, thickness * 2.1, Color(aura, 0.0), Color(aura, 0.26),
		Color(aura, 0.16), Color(aura, 0.0), head, fade, tail)
	# The blade's tip while it sweeps.
	if head < 1.0:
		glow(ci, tip, reach * 0.14 + 7.0, Color(light, 0.6 * fade))
	_sparks(ci, center, angle, reach, half, light, head, fade, age, seed)
	# Impact: flash, star and a small ring where the sweep ends.
	var pop := clampf((age - SWEEP_END) / 0.2, 0.0, 1.0)
	if head >= 1.0 and pop < 1.0:
		var k := (1.0 - pop) * fade
		glow(ci, tip, reach * (0.18 + 0.16 * pop), Color(light, 0.85 * k))
		star(ci, tip, reach * (0.14 + 0.1 * pop), seed, Color(1.0, 1.0, 1.0, 0.8 * k), 2.5)
		ring(ci, tip, reach * (0.06 + 0.2 * pop), Color(aura, 0.7 * k))
	match style:
		WeaponData.SlashStyle.FLAME:
			_embers(ci, center, angle, reach, half, head, fade, age, seed)
		WeaponData.SlashStyle.RUNIC:
			_arc_lightning(ci, center, angle, reach * 0.88, half, head, fade, age)
		WeaponData.SlashStyle.HEAVY:
			for k in 3:
				var a := tip_angle - 0.25 * (k + 1)
				ci.draw_arc(center, reach * (1.05 + 0.05 * k), a - 0.2, a, 6, Color(light, 0.5 * fade), 2.5, true)
		WeaponData.SlashStyle.SMASH:
			if age > 0.2:
				var impact := center + Vector2.from_angle(angle) * radius * 0.7
				var wave := clampf((age - 0.2) / 0.6, 0.0, 1.0)
				ring(ci, impact, radius * (0.2 + 0.6 * wave), Color(aura, 0.85 * fade))
				glow(ci, impact, radius * 0.25 * (1.0 - wave), Color(light, 0.6 * fade))


## Moment (share of the swing's life) the blade finishes its sweep: Vfx.SWEEP.
const SWEEP_END := 0.4


## Sparks shed along the arc once the blade has passed them, drifting outward.
func _sparks(ci: CanvasItem, center: Vector2, angle: float, radius: float, half: float, light: Color,
		head: float, fade: float, age: float, seed: float) -> void:
	for k in SPARKS:
		var u := fposmod(seed * 0.37 + k * 0.143, 1.0)
		if u > head:
			continue
		var lived := (age - SWEEP_END * u) / 0.5
		if lived <= 0.0 or lived >= 1.0:
			continue
		var a := angle - half + half * 2.0 * u
		var dir := Vector2.from_angle(a)
		var at := center + dir * radius * (1.0 + 0.35 * lived) + dir.orthogonal() * radius * 0.05 * sin(seed + k)
		var k_alpha := (1.0 - lived) * fade
		glow(ci, at, 7.0 * (1.0 - lived * 0.5), Color(light, 0.9 * k_alpha))


func _embers(ci: CanvasItem, center: Vector2, angle: float, radius: float, half: float, head: float,
		fade: float, age: float, seed: float) -> void:
	for k in EMBERS:
		var u := fposmod(seed * 0.29 + k * 0.125, 1.0)
		if u > head:
			continue
		var lived := (age - SWEEP_END * u) / 0.6
		if lived <= 0.0 or lived >= 1.0:
			continue
		var a := angle - half + half * 2.0 * u
		var at := center + Vector2.from_angle(a) * radius * 0.98 + Vector2(sin(seed * 3.0 + k) * 10.0, -50.0 * lived)
		glow(ci, at, 6.0 * (1.0 - lived * 0.6), Color(1.0, 0.6 + 0.3 * lived, 0.2, 0.95 * (1.0 - lived) * fade))


func _arc_lightning(ci: CanvasItem, center: Vector2, angle: float, radius: float, half: float,
		head: float, fade: float, age: float) -> void:
	_line.resize(POINTS)
	for k in POINTS:
		var u := float(k) / (POINTS - 1) * head
		var a := angle - half + half * 2.0 * u
		var jitter := (fposmod(sin(k * 12.9898 + floor(age * 30.0)) * 43758.5453, 1.0) - 0.5) * radius * 0.12
		_line[k] = center + Vector2.from_angle(a) * (radius + jitter)
	ci.draw_polyline(_line, Color(0.3, 0.7, 1.0, 0.45 * fade), 7.0, true)
	ci.draw_polyline(_line, Color(0.85, 1.0, 1.0, fade), 2.0, true)


## Smash (hammer): dust puffs thrown up around the impact point.
func _dust(ci: CanvasItem, center: Vector2, angle: float, radius: float, age: float, fade: float, seed: float) -> void:
	var impact := center + Vector2.from_angle(angle) * radius * 0.7
	var lived := clampf((age - 0.2) / 0.7, 0.0, 1.0)
	for k in 6:
		var d := Vector2.from_angle(seed + k * TAU / 6.0)
		var at := impact + d * radius * (0.12 + 0.3 * lived) + Vector2(0.0, -radius * 0.08 * lived)
		glow(ci, at, radius * (0.1 + 0.08 * lived), Color(0.25, 0.2, 0.3, 0.3 * (1.0 - lived) * fade))


# --- Thrust (spear, rapier) ----------------------------------------------------

## A long tapering spike: white-hot center, colored flanks, feathered edges.
func spike(ci: CanvasItem, center: Vector2, angle: float, radius: float, color: Color, light: Color,
		head: float, fade: float) -> void:
	if fade <= 0.01:
		return
	var dir := Vector2.from_angle(angle)
	var side := dir.orthogonal()
	var base := center + dir * radius * 0.15
	var tip := center + dir * radius * (0.35 + 0.65 * head)
	var w := radius * 0.1 * (0.4 + 0.6 * fade)
	_spike_verts.resize(4)
	_spike_cols.resize(4)
	_spike_verts[0] = base + side * w
	_spike_verts[1] = base
	_spike_verts[2] = base - side * w
	_spike_verts[3] = tip
	_spike_cols[0] = Color(color, 0.0)
	_spike_cols[1] = Color(Color.WHITE.lerp(light, 0.2), fade)
	_spike_cols[2] = Color(color, 0.0)
	_spike_cols[3] = Color(light, 0.0)
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), _spike_tris, _spike_verts, _spike_cols)
	# A narrower, more opaque layer on top: the body of the spike.
	_spike_verts[0] = base + side * w * 0.45
	_spike_verts[2] = base - side * w * 0.45
	_spike_cols[0] = Color(color, 0.75 * fade)
	_spike_cols[2] = Color(color, 0.75 * fade)
	_spike_cols[3] = Color(light, 0.2 * fade)
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), _spike_tris, _spike_verts, _spike_cols)


func _spike_glow(ci: CanvasItem, center: Vector2, angle: float, radius: float, color: Color, light: Color,
		head: float, fade: float, age: float) -> void:
	var dir := Vector2.from_angle(angle)
	var base := center + dir * radius * 0.15
	var tip := center + dir * radius * (0.35 + 0.65 * head)
	for k in 5:
		glow(ci, base.lerp(tip, 0.2 + 0.2 * k), radius * 0.13, Color(color, 0.22 * fade))
	glow(ci, tip, radius * 0.16, Color(light, 0.7 * fade))
	for k in [-1.0, 1.0]:
		var off: Vector2 = dir.orthogonal() * radius * 0.2 * k
		ci.draw_line(base.lerp(tip, 0.2) + off, base.lerp(tip, 0.75) + off, Color(light, 0.45 * fade), 2.0, true)
	if head >= 0.95:
		var pop := clampf((age - SWEEP_END) / 0.2, 0.0, 1.0)
		star(ci, tip, radius * 0.16 * (1.0 - pop), angle + 0.4, Color(1.0, 1.0, 1.0, 0.85 * fade * (1.0 - pop)), 2.5)


# --- Beam ----------------------------------------------------------------------

## Laser: soft wide aura, colored body, white-hot core, flares at both ends.
func beam_glow(ci: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color, t: float) -> void:
	var light := color.lerp(Color.WHITE, 0.7)
	ci.draw_line(from, to, Color(color, 0.18 * t), width * 3.6 + 6.0, true)
	ci.draw_line(from, to, Color(color, 0.55 * t), width * 1.5 + 2.0, true)
	ci.draw_line(from, to, Color(light, t), maxf(width * 0.45, 2.0), true)
	glow(ci, from, width * 1.8 + 8.0, Color(light, 0.55 * t))
	glow(ci, to, width * 2.6 + 10.0, Color(light, 0.75 * t))


# --- Explosion -----------------------------------------------------------------

## Fire colors from white-hot to ember red as the blast ages (0..1).
static func fire_color(color: Color, age: float) -> Color:
	var hot := Color(1.0, 0.8, 0.35)
	var warm := color.lerp(Color(1.0, 0.55, 0.15), 0.5)
	var cool := Color(0.55, 0.12, 0.08)
	return hot.lerp(warm, clampf(age * 2.5, 0.0, 1.0)).lerp(cool, clampf(age * 1.6 - 0.5, 0.0, 1.0))


## Smoke (normal blending): dark soft puffs rising late in the blast.
func explosion_body(ci: CanvasItem, center: Vector2, radius: float, seed: float, age: float, busy: bool) -> void:
	if age < 0.3:
		return
	var smoke := (age - 0.3) / 0.7
	var puffs := 2 if busy else 4
	for k in puffs:
		var a := seed * 2.3 + k * TAU / puffs
		var at := center + Vector2.from_angle(a) * radius * (0.4 + 0.35 * smoke) + Vector2(0.0, -radius * 0.25 * smoke)
		glow(ci, at, radius * 0.34 * (1.0 - smoke * 0.3), Color(0.14, 0.1, 0.18, 0.4 * (1.0 - smoke)))


## Additive layer: a flash, the fireball (overlapping soft lobes), a shock ring and embers.
func explosion_glow(ci: CanvasItem, center: Vector2, radius: float, seed: float, color: Color, age: float,
		busy: bool) -> void:
	var t := 1.0 - age
	var grow := sqrt(age)
	var fire := fire_color(color, age)
	if age < 0.3:
		var k := 1.0 - age / 0.3
		glow(ci, center, radius * (0.8 + 0.5 * age), Color(1.0, 0.85, 0.5, 0.55 * k))
	# Fireball lobes: a ring of soft blobs around a hot center, swelling then fading.
	var swell := minf(age / 0.25, 1.0) * (1.0 - smoothstep(0.45, 1.0, age))
	if swell > 0.02:
		var lobes := 4 if busy else 7
		for k in lobes:
			var a := seed + k * TAU / lobes
			var at := center + Vector2.from_angle(a) * radius * 0.5 * grow
			var r := radius * (0.38 + 0.08 * sin(seed * 7.0 + k * 2.1)) * swell
			glow(ci, at, r, Color(fire, 0.75))
		glow(ci, center, radius * 0.45 * swell, Color(fire.lerp(Color.WHITE, 0.3), 0.45))
	ring(ci, center, radius * (0.35 + 0.8 * grow), Color(fire.lerp(color, 0.5), 0.6 * t))
	var embers := 3 if busy else EMBERS
	for k in embers:
		var a := seed * 1.7 + k * TAU / embers + 0.4
		var dist := radius * (0.4 + 0.95 * pow(age, 0.55))
		var at := center + Vector2.from_angle(a) * dist + Vector2(0.0, 30.0 * age * age)
		glow(ci, at, 5.0 * t + 1.5, Color(1.0, 0.75, 0.3, t))


# --- Hit and lightning ------------------------------------------------------------

func hit_glow(ci: CanvasItem, pos: Vector2, size: float, seed: float, color: Color, t: float) -> void:
	glow(ci, pos, size * 1.2, Color(color, 0.7 * t))
	star(ci, pos, size * (0.6 + 0.6 * (1.0 - t)), seed, Color(1.0, 1.0, 1.0, t), 2.0)


func lightning_glow(ci: CanvasItem, from: Vector2, to: Vector2, seed: float, color: Color, t: float) -> void:
	const SEGMENTS := 6
	var normal := (to - from).orthogonal().normalized()
	var jitter := from.distance_to(to) * 0.18
	_line.resize(SEGMENTS + 1)
	_line[0] = from
	for k in range(1, SEGMENTS):
		var noise := fposmod(sin(seed * 12.9898 + k * 78.233) * 43758.5453, 1.0) - 0.5
		_line[k] = from.lerp(to, float(k) / SEGMENTS) + normal * noise * jitter
	_line[SEGMENTS] = to
	ci.draw_polyline(_line, Color(color, 0.35 * t), 10.0, true)
	ci.draw_polyline(_line, Color(color.lerp(Color.WHITE, 0.6), t), 2.5, true)
	glow(ci, to, 12.0, Color(color, 0.6 * t))
