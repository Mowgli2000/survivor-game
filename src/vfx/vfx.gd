class_name Vfx
extends Node2D
## Short-lived combat effects (slashes, beams, explosions, sparks, lightning),
## stored in flat arrays and drawn by a single canvas item. Flat manga style
## (art bible): black ink outline, flat color, light core; normal blending.
## Also the feedback hub: big effects request a camera shake.

signal shake_requested(amount: float)

enum Kind { SLASH, BEAM, EXPLOSION, HIT, LIGHTNING, WARN_CIRCLE, WARN_LINE, PORTAL, DEATH }

const CAPACITY := 384
## Late game (Zone stat, many weapons) the drawn effects stay readable: past these sizes
## the picture grows at a fraction of the real hit area (the hits themselves are untouched).
## Slashes are drawn at their real size up to 320 px (playtest: with the cap at 140, more
## Zone or Range on a melee weapon did not show, every base slash being already past it).
const SLASH_FULL := 460.0
const BLAST_FULL := 170.0
const BEAM_FULL := 10.0
const BEAM_MAX := 22.0
const OVERSIZE_SHARE := 0.5
## Past this many live effects, new swings, beams and blasts fade sooner (visual noise).
const BUSY_COUNT := 40
const BUSY_LIFE := 0.6
## Coop: two players' effects share the screen, drawn a bit smaller.
var coop_scale: float = 1.0
## Outline color of every effect (the art's black line).
const INK := Color(0.05, 0.04, 0.1)
## Gate color: monsters step out of violet portals (art bible).
const PORTAL_COLOR := Color(0.64, 0.35, 1.0)
const SLASH_LIFE := 0.26
const SLASH_LIFE_SLOW := 0.36
## Share of a slash's life spent sweeping across its arc.
const SWEEP := 0.4
## Premium pass: a fuller blast, see-through (additive) so the monsters stay readable.
const BLAST_LIFE := 0.48
## Monster death "pop": flash and ring (no flying chunks: visual noise, playtest).
const DEATH_LIFE := 0.42

var _kind := PackedInt32Array()
var _a := PackedVector2Array()       # center / start
var _b := PackedVector2Array()       # direction / end
var _size := PackedFloat32Array()    # radius / width
var _extra := PackedFloat32Array()   # half angle / random seed
var _life := PackedFloat32Array()
var _max_life := PackedFloat32Array()
var _color := PackedColorArray()
var _style := PackedInt32Array()     # slash style (WeaponData.SlashStyle)
var _seedv := PackedFloat32Array()   # random seed of the effect
## Node an effect follows while it lasts (a melee swing or a beam moves with its owner:
## the hero keeps walking), and where that node was last frame. Null = stays in place.
var _follow: Array[Node2D] = []
var _follow_last := PackedVector2Array()
static var _puff_cache: ImageTexture
var _art := VfxArt.new()
## Additive layer (auras, sparks, flashes): a child drawn with additive blending.
var _glow: Node2D
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
	_glow = Node2D.new()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	_glow.draw.connect(_draw_additive)
	add_child(_glow)
	_kind.resize(CAPACITY)
	_a.resize(CAPACITY)
	_b.resize(CAPACITY)
	_size.resize(CAPACITY)
	_extra.resize(CAPACITY)
	_life.resize(CAPACITY)
	_max_life.resize(CAPACITY)
	_color.resize(CAPACITY)
	_style.resize(CAPACITY)
	_follow_last.resize(CAPACITY)
	_seedv.resize(CAPACITY)
	_follow.resize(CAPACITY)


func active_count() -> int:
	return _count


## Melee hit drawn in the weapon's style (WeaponData.SlashStyle): the blade
## sweeps across the arc, then the trail thins and fades.
func slash(center: Vector2, angle: float, radius: float, half_angle: float, color: Color,
		style: int = 0, follower: Node2D = null) -> void:
	var life := SLASH_LIFE_SLOW if style == WeaponData.SlashStyle.HEAVY or style == WeaponData.SlashStyle.SMASH 		else SLASH_LIFE
	_add(Kind.SLASH, center, Vector2.from_angle(angle), shown_size(radius, SLASH_FULL), half_angle,
		color, life, style, follower)
	# The weapon winds up first: the streak starts when its strike does.
	if _count > 0:
		_life[_count - 1] += WeaponVisuals.strike_delay(style)
	# Heavy blows shake the screen a little (more when they smash).
	if style == WeaponData.SlashStyle.SMASH:
		shake_requested.emit(0.1)
	elif style == WeaponData.SlashStyle.HEAVY:
		shake_requested.emit(0.06)


func beam(from: Vector2, to: Vector2, width: float, color: Color, follower: Node2D = null) -> void:
	_add(Kind.BEAM, from, to, minf(shown_size(width, BEAM_FULL), BEAM_MAX), 0.0, color, 0.14, 0, follower)


func explosion(center: Vector2, radius: float, color: Color, shake: bool) -> void:
	_add(Kind.EXPLOSION, center, Vector2.ZERO, shown_size(radius, BLAST_FULL), _next_seed(), color, BLAST_LIFE)
	if shake:
		shake_requested.emit(clampf(radius / 400.0, 0.1, 0.4))


## A monster dies: short flash and ring in its color (`radius` = its size).
func death(center: Vector2, radius: float, color: Color) -> void:
	_add(Kind.DEATH, center, Vector2.ZERO, radius, _next_seed(), color, DEATH_LIFE)


## Size drawn for a real size `real`: it follows up to `full`, then grows at OVERSIZE_SHARE.
func shown_size(real: float, full: float) -> float:
	var size := real if real <= full else full + (real - full) * OVERSIZE_SHARE
	return size * coop_scale


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
	Audio.play(Sounds.WARNING, -10.0, 0.04)
	_add(Kind.WARN_CIRCLE, center, Vector2.ZERO, radius, 0.0, color, life)


## Boss telegraph: a band showing a dash path or an aimed shot.
func warning_line(from: Vector2, to: Vector2, width: float, color: Color, life: float) -> void:
	Audio.play(Sounds.WARNING, -10.0, 0.04, 1.15)
	_add(Kind.WARN_LINE, from, to, width, 0.0, color, life)


func _add(kind: Kind, a: Vector2, b: Vector2, size: float, extra: float, color: Color, life: float,
		style: int = 0, follower: Node2D = null) -> void:
	if _count >= CAPACITY:
		return  # Dropping a cosmetic effect is better than a frame spike.
	if _count > BUSY_COUNT and (kind == Kind.SLASH or kind == Kind.EXPLOSION or kind == Kind.BEAM):
		life *= BUSY_LIFE
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
	_seedv[i] = _next_seed()
	_follow[i] = follower
	if follower != null:
		_follow_last[i] = follower.global_position
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
			continue
		var follower := _follow[i]
		if follower != null:
			if is_instance_valid(follower):
				var moved := follower.global_position - _follow_last[i]
				_a[i] += moved
				if _kind[i] == Kind.BEAM:
					_b[i] += moved  # a slash's _b is a direction: it stays
				_follow_last[i] = follower.global_position
			else:
				_follow[i] = null
	_drawn = _count > 0
	queue_redraw()
	_glow.queue_redraw()


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
	_seedv[i] = _seedv[last]
	_follow[i] = _follow[last]
	_follow_last[i] = _follow_last[last]
	_follow[last] = null
	_count = last


func _draw() -> void:
	var busy := _count > BUSY_COUNT
	for i in _count:
		var t := _life[i] / _max_life[i]  # 1 -> 0
		if t > 1.0:
			continue  # waiting for the weapon's wind-up to end
		var color := _color[i]
		match _kind[i]:
			Kind.SLASH:
				_draw_slash(_a[i], _b[i].angle(), _size[i], _extra[i], color, t, _style[i], _seedv[i], false)
			Kind.EXPLOSION:
				_art.explosion_body(self, _a[i], _size[i], _extra[i], 1.0 - t, busy)
			Kind.DEATH:
				_draw_death(_a[i], _size[i], _extra[i], color, t)
			Kind.WARN_CIRCLE:
				draw_circle(_a[i], _size[i] * (1.0 - t), Color(color, 0.25))
				draw_arc(_a[i], _size[i], 0.0, TAU, 48, Color(INK, 0.6), 6.0, true)
				draw_arc(_a[i], _size[i], 0.0, TAU, 48, Color(color, 0.85), 3.0, true)
			Kind.PORTAL:
				_draw_portal(_a[i], _size[i], color, t)
			Kind.WARN_LINE:
				draw_line(_a[i], _b[i], Color(color, 0.15 + 0.2 * (1.0 - t)), _size[i], true)
				draw_line(_a[i], _b[i], Color(color, 0.8), 2.0, true)


## The additive layer: glows, auras, sparks and flashes of every effect.
func _draw_additive() -> void:
	var busy := _count > BUSY_COUNT
	for i in _count:
		var t := _life[i] / _max_life[i]
		if t > 1.0:
			continue
		var color := _color[i]
		match _kind[i]:
			Kind.SLASH:
				_draw_slash(_a[i], _b[i].angle(), _size[i], _extra[i], color, t, _style[i], _seedv[i], true)
			Kind.BEAM:
				_art.beam_glow(_glow, _a[i], _b[i], _size[i], color, t)
			Kind.EXPLOSION:
				_art.explosion_glow(_glow, _a[i], _size[i], _extra[i], color, 1.0 - t, busy)
			Kind.DEATH:
				if _count <= BUSY_COUNT * 3:
					_art.death_motes(_glow, _a[i], _size[i], _extra[i], color, t, 3 if not busy else 2)
			Kind.HIT:
				_art.hit_glow(_glow, _a[i], _size[i], _extra[i], color, t)
			Kind.LIGHTNING:
				_art.lightning_glow(_glow, _a[i], _b[i], _extra[i], color, t)


func _draw_slash(center: Vector2, angle: float, radius: float, half: float, color: Color, t: float,
		style: int, seed: float, glow_layer: bool) -> void:
	var age := 1.0 - t
	# Fast start, soft landing: the blade whips across then settles (ease-out).
	var head := 1.0 - pow(1.0 - clampf(age / SWEEP, 0.0, 1.0), 2.4)
	var fade := clampf(t / (1.0 - SWEEP), 0.0, 1.0)      # the trail thins once the sweep is done
	if glow_layer:
		_art.slash_glow(_glow, center, angle, radius, half, color, style, head, fade, age, seed)
	else:
		_art.slash_body(self, center, angle, radius, half, color, style, head, fade, age, seed)


## Monster death "pop": a flash and a ring of its size. One per kill: plain
## circles and arcs only.
## The monster "poofs": a white flash hides its sprite, then a few smoke puffs (inked
## discs tinted by the monster's color) swell and fade. Puffs are one textured quad
## each (a baked disc): a polygon circle per puff cost ~20 FPS in the stress test.
func _draw_death(center: Vector2, radius: float, noise_seed: float, color: Color, t: float) -> void:
	var age := 1.0 - t
	var out := 1.0 - (1.0 - age) * (1.0 - age)  # ease out
	if age < 0.3:
		_puff(center, radius * (0.75 + 0.5 * age / 0.3), Color(1.0, 1.0, 1.0, 0.8 * (1.0 - age / 0.3)))
	var puff_color := Color(0.94, 0.91, 1.0).lerp(color, 0.22)
	var fade := clampf(t * 1.6, 0.0, 1.0)
	puff_color.a = 0.95 * fade
	_puff(center, radius * (0.5 + 0.45 * out), puff_color)
	var puffs := 4 if _count <= BUSY_COUNT else 2
	for k in puffs:
		var angle := noise_seed * TAU + k * TAU / puffs + sin(noise_seed * 40.0 + k) * 0.25
		var spread := radius * (0.2 + 0.85 * out) * (0.85 + 0.3 * fposmod(noise_seed * 7.0 + k * 0.37, 1.0))
		var at := center + Vector2.from_angle(angle) * spread + Vector2(0.0, -radius * 0.35 * out)
		_puff(at, radius * (0.34 + 0.22 * out) * (1.0 - 0.45 * age), puff_color)


## One disc of smoke centered on `at`, `radius` px, tinted `tint`.
func _puff(at: Vector2, radius: float, tint: Color) -> void:
	draw_texture_rect(_puff_texture(), Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, tint)


## White disc with a soft ink outline, baked once and shared by every Vfx.
static func _puff_texture() -> ImageTexture:
	if _puff_cache != null:
		return _puff_cache
	const SIZE := 48
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var half := SIZE * 0.5
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length() / half
			var inside := 1.0 - smoothstep(0.93, 1.0, d)
			var ink := smoothstep(0.78, 0.84, d)
			var rgb := Color(1.0, 1.0, 1.0).lerp(INK, ink)
			image.set_pixel(x, y, Color(rgb, inside * lerpf(1.0, 0.6, ink)))
	_puff_cache = ImageTexture.create_from_image(image)
	return _puff_cache


func _draw_portal(center: Vector2, radius: float, color: Color, t: float) -> void:
	# Opens then closes (0 -> 1 -> 0 over its life).
	var r := radius * sin(PI * (1.0 - t))
	draw_circle(center, r, Color(INK, 0.6))
	draw_arc(center, r, 0.0, TAU, 16, color, 4.0)
