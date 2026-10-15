class_name Vfx
extends Node2D
## Short-lived combat effects (slashes, beams, explosions, sparks, lightning),
## stored in flat arrays and drawn by a single canvas item. Flat manga style
## (art bible): black ink outline, flat color, light core; normal blending.
## Also the feedback hub: big effects request a camera shake.

signal shake_requested(amount: float)

enum Kind { SLASH, BEAM, EXPLOSION, HIT, LIGHTNING, WARN_CIRCLE, WARN_LINE, PORTAL, DEATH, SHEET }

const CAPACITY := 384
const PAINT_SHADER := preload("res://src/vfx/painted_effect.gdshader")
## Radius around a hero (world px) where painted effects fade out so he stays visible.
const GUARD_RADIUS := MeleeArcBehavior.RING_GAP  # nothing painted inside the ring of floating weapons
## Late game (Zone stat, many weapons) the drawn effects stay readable: past these sizes
## the picture grows at a fraction of the real hit area (the hits themselves are untouched).
## Slashes are drawn at their real size up to 320 px (playtest: with the cap at 140, more
## Zone or Range on a melee weapon did not show, every base slash being already past it).
const SLASH_FULL := 460.0
const BLAST_FULL := 170.0
const BEAM_FULL := 10.0
const BEAM_MAX := 22.0
## Share of a looping sheet's life spent fading in and out.
const LOOP_FADE := 0.08
## Draw order of the ground layer: above the arena floor (-10) and the pickups (-1), under every creature.
const GROUND_Z := -5
## Burning ground is also drawn over the creatures at this share of its opacity (the hero's zone cleared): flames lick
## the monsters' legs instead of the monsters looking cut out of a flat decal. 0 = only under them.
const GROUND_FRONT_SHARE := 0.3
## Readability (ADR 0030, revised twice): painted swings, impacts and blasts are fully opaque and last 0.18-0.25 s (shorter
## ones were invisible to the eye): visible from the first frame, they fade out only over their last FADE_OUT seconds.
## Ground zones stay see-through.
const PAINTED_OPACITY := 1.0
const GROUND_OPACITY := 0.45
const FADE_OUT := 0.05
## Drawn height of a painted chain bolt's frame, px (its zigzag stays within about a third of it).
const BOLT_HEIGHT := 220.0
## A painted beam's frame is this many times as tall as the beam is wide (its core stays about as thick as what hurts).
const BEAM_HEIGHT_PER_WIDTH := 18.0
const OVERSIZE_SHARE := 0.5
## Past this many live effects, new swings, beams and blasts fade sooner (visual noise).
const BUSY_COUNT := 40
## How far a painted blast reaches, as a share of the damage radius (its glow goes a little beyond).
const PAINTED_BLAST_SHARE := 1.05
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

## How a SHEET effect moves (stored in _style, its parameter in _extra): in place, flying along its
## direction over _extra px, circling its center at radius _extra, stretched along a line from _a over
## _size px with a drawn height of _extra px (beams, bolts), or falling along its direction over _extra px
## with its head (EffectSheet.head) landing on the end point (meteors, turned by EffectSheet.art_angle), or replaying its
## frames _extra times over its life, fading in and out (burning ground).
enum SheetMode { PLAIN, TRAVEL, ORBIT, STRETCH, FALL, LOOP, GROUND }
## Angle swept by an orbiting sheet over its life, radians.
const ORBIT_SWEEP := TAU * 0.75

## Debug (F3): outlines of the real damage shapes, to check them against the painted effects.
var show_shapes: bool = false
var _debug_shapes: Array = []  # [kind, a, b, r, min_dot, age]
const DEBUG_SHAPE_LIFE := 0.6

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
## Painted animation of a SHEET effect (null for the others).
var _sheet: Array[EffectSheet] = []
static var _puff_cache: ImageTexture
var _art := VfxArt.new()
## Additive layer (auras, sparks, flashes): a child drawn with additive blending.
var _glow: Node2D
## Painted layer (SHEET effects): premultiplied alpha, so dark parts of the art darken the floor.
var _paint: Node2D
var _paint_material: ShaderMaterial
## Ground layer (burning ground): drawn under the monsters and the hero, never cleared around a hero.
var _ground: Node2D
## Heroes a painted effect must not hide (see painted_effect.gdshader), set by Run.
var _guarded: Array[Node2D] = []
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
	_paint = Node2D.new()
	_paint_material = ShaderMaterial.new()
	_paint_material.shader = PAINT_SHADER
	_paint.material = _paint_material
	# No painted effect enters the hero's zone: it is cleared inside GUARD_RADIUS (the ring of floating weapons).
	_paint_material.set_shader_parameter("floor_alpha", 0.0)
	_paint.draw.connect(_draw_paint)
	_paint.visible = false
	add_child(_paint)
	_ground = Node2D.new()
	_ground.z_as_relative = false
	_ground.z_index = GROUND_Z
	var ground_material := ShaderMaterial.new()
	ground_material.shader = PAINT_SHADER
	ground_material.set_shader_parameter("floor_alpha", 1.0)
	_ground.material = ground_material
	_ground.draw.connect(_draw_ground)
	_ground.visible = false
	add_child(_ground)
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
	_sheet.resize(CAPACITY)


## The heroes whose silhouette painted effects leave visible (a swing never hides the player).
func guard(heroes: Array[Node2D]) -> void:
	_guarded = heroes


func _update_guard() -> void:
	var viewport := get_viewport()
	var to_screen := viewport.get_final_transform() * viewport.get_canvas_transform()
	var far := Vector2(-10000.0, -10000.0)
	var spots: Array[Vector2] = [far, far]
	for k in mini(_guarded.size(), 2):
		if is_instance_valid(_guarded[k]):
			spots[k] = to_screen * _guarded[k].global_position
	_paint_material.set_shader_parameter("guard_a", spots[0])
	_paint_material.set_shader_parameter("guard_b", spots[1])
	_paint_material.set_shader_parameter("guard_radius", GUARD_RADIUS * to_screen.get_scale().x)


func debug_circle(center: Vector2, radius: float, dir: Vector2, min_dot: float) -> void:
	_debug_shapes.append([0, center, dir, radius, min_dot, 0.0])


func debug_segment(from: Vector2, to: Vector2, half_width: float) -> void:
	_debug_shapes.append([1, from, to, half_width, 0.0, 0.0])


func _draw_debug_shapes() -> void:
	for shape in _debug_shapes:
		var fade: float = 1.0 - float(shape[5]) / DEBUG_SHAPE_LIFE
		var color := Color(1.0, 0.1, 0.9, fade)
		if shape[0] == 0:
			draw_arc(shape[1], shape[3], 0.0, TAU, 48, color, 2.0)
			if shape[4] > -1.0:
				var a: float = shape[2].angle()
				var half: float = acos(clampf(shape[4], -1.0, 1.0))
				draw_line(shape[1], shape[1] + Vector2.from_angle(a - half) * shape[3], color, 2.0)
				draw_line(shape[1], shape[1] + Vector2.from_angle(a + half) * shape[3], color, 2.0)
		else:
			var side: Vector2 = (shape[2] - shape[1]).orthogonal().normalized() * shape[3]
			draw_line(shape[1] + side, shape[2] + side, color, 2.0)
			draw_line(shape[1] - side, shape[2] - side, color, 2.0)
			draw_line(shape[1] + side, shape[1] - side, color, 2.0)
			draw_line(shape[2] + side, shape[2] - side, color, 2.0)


func active_count() -> int:
	return _count


## Melee hit drawn in the weapon's style (WeaponData.SlashStyle): the blade
## sweeps across the arc, then the trail thins and fades.
func slash(center: Vector2, angle: float, radius: float, half_angle: float, color: Color,
		style: int = 0, follower: Node2D = null, sheet: EffectSheet = null, delay: float = 0.0) -> void:
	var life := SLASH_LIFE_SLOW if style == WeaponData.SlashStyle.HEAVY or style == WeaponData.SlashStyle.SMASH 		else SLASH_LIFE
	if sheet != null:
		# Painted swing: the sheet plays over its own duration, centered on the swordsman.
		_add_sheet(sheet, center, angle, shown_size(radius, SLASH_FULL), follower)
	else:
		_add(Kind.SLASH, center, Vector2.from_angle(angle), shown_size(radius, SLASH_FULL), half_angle,
			color, life, style, follower)
	# The weapon winds up first: the streak starts when its strike does.
	if _count > 0:
		_life[_count - 1] += WeaponVisuals.strike_delay(style) + delay
	# Heavy blows shake the screen a little (more when they smash).
	if style == WeaponData.SlashStyle.SMASH:
		shake_requested.emit(0.1)
	elif style == WeaponData.SlashStyle.HEAVY:
		shake_requested.emit(0.06)


## A painted animation (EffectSheet) played once at `pos`, pointing along `angle`, `size` = the
## radius it covers. `delay`: seconds before it starts; `follower`: node it moves with.
func sheet(effect: EffectSheet, pos: Vector2, angle: float, size: float, tint: Color = Color.WHITE,
		optional: bool = false, delay: float = 0.0, follower: Node2D = null) -> void:
	if optional and _count > BUSY_COUNT:
		return  # a hit burst is not worth a frame when the screen is already full of effects
	_add_sheet(effect, pos, angle, shown_size(size, BLAST_FULL), follower, tint, SheetMode.PLAIN, 0.0, delay)


## A painted animation fitted to a real shape (a damage circle, a line): its art spans `half_extent` px
## from its center, so what is drawn is what hurts. `delay`: seconds before it starts.
func sheet_at(effect: EffectSheet, pos: Vector2, angle: float, half_extent: float, delay: float = 0.0,
		follower: Node2D = null, optional: bool = false) -> void:
	if optional and _count > BUSY_COUNT:
		return
	_add_sheet(effect, pos, angle, effect.size_for(half_extent), follower, Color.WHITE, SheetMode.PLAIN, 0.0, delay)


func sheet_travel_at(effect: EffectSheet, pos: Vector2, angle: float, half_extent: float, distance: float,
		delay: float = 0.0, follower: Node2D = null) -> void:
	_add_sheet(effect, pos, angle, effect.size_for(half_extent), follower, Color.WHITE, SheetMode.TRAVEL, distance, delay)


## A painted one-shot on the ground: under the hero and the monsters, with a thin copy over them.
func sheet_ground_at(effect: EffectSheet, pos: Vector2, half_extent: float, delay: float = 0.0) -> void:
	_add_sheet(effect, pos, 0.0, effect.size_for(half_extent), null, Color.WHITE, SheetMode.GROUND, 0.0, delay)


func sheet_orbit_at(effect: EffectSheet, pos: Vector2, angle: float, half_extent: float, radius: float,
		follower: Node2D = null) -> void:
	_add_sheet(effect, pos, angle, effect.size_for(half_extent), follower, Color.WHITE, SheetMode.ORBIT, radius)


## A painted animation that flies from `pos` along `angle` over `distance` while it plays.
func sheet_travel(effect: EffectSheet, pos: Vector2, angle: float, size: float, distance: float,
		follower: Node2D = null) -> void:
	_add_sheet(effect, pos, angle, shown_size(size, SLASH_FULL), follower, Color.WHITE, SheetMode.TRAVEL,
		distance * coop_scale)


## A painted animation that circles `pos` at `radius`, starting at `angle` and sweeping ORBIT_SWEEP.
func sheet_orbit(effect: EffectSheet, pos: Vector2, angle: float, size: float, radius: float,
		follower: Node2D = null) -> void:
	_add_sheet(effect, pos, angle, shown_size(size, SLASH_FULL), follower, Color.WHITE, SheetMode.ORBIT,
		radius * coop_scale)


## A painted beam or bolt from `from` to `to`: the art is stretched to the line's length, `height` px tall.
func sheet_stretch(effect: EffectSheet, from: Vector2, to: Vector2, height: float, follower: Node2D = null) -> void:
	var line := to - from
	_add_sheet(effect, from, line.angle(), line.length(), follower, Color.WHITE, SheetMode.STRETCH, height)


## A painted object falling onto `impact` from `distance` px away along `angle`, over its whole life.
## `size`: side of its frame. `delay`: seconds before it starts.
func sheet_fall(effect: EffectSheet, impact: Vector2, angle: float, size: float, distance: float,
		delay: float = 0.0) -> void:
	var direction := Vector2.from_angle(angle)
	_add_sheet(effect, impact - direction * distance, angle, size * coop_scale, null, Color.WHITE, SheetMode.FALL,
		distance, delay)


## A painted loop on the ground (burning flask): `effect` replays over `seconds`, fitted to `half_extent` px.
func sheet_loop(effect: EffectSheet, pos: Vector2, half_extent: float, seconds: float) -> void:
	_add_sheet(effect, pos, 0.0, effect.size_for(half_extent), null, Color.WHITE, SheetMode.LOOP,
		seconds / maxf(effect.duration, 0.05), 0.0, seconds)


func _add_sheet(effect: EffectSheet, pos: Vector2, angle: float, size: float, follower: Node2D,
		tint: Color = Color.WHITE, mode: int = SheetMode.PLAIN, extra: float = 0.0, delay: float = 0.0,
		life: float = -1.0) -> void:
	var before := _count
	_add(Kind.SHEET, pos, Vector2.from_angle(angle), size, extra, tint, life if life > 0.0 else effect.duration, mode, follower)
	if _count > before:
		_sheet[before] = effect
		_life[before] += delay  # life above its maximum = not started yet (hidden until it counts down)


func beam(from: Vector2, to: Vector2, width: float, color: Color, follower: Node2D = null,
		painted: EffectSheet = null) -> void:
	if painted != null:
		sheet_stretch(painted, from, to, width * BEAM_HEIGHT_PER_WIDTH, follower)
		return
	_add(Kind.BEAM, from, to, minf(shown_size(width, BEAM_FULL), BEAM_MAX), 0.0, color, 0.14, 0, follower)


func explosion(center: Vector2, radius: float, color: Color, shake: bool, painted: EffectSheet = null) -> void:
	if painted != null:
		# Fitted: the painted blast spans (about) the radius that really hurts.
		_add_sheet(painted, center, 0.0, painted.size_for(radius * PAINTED_BLAST_SHARE), null)
	else:
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


## One hop of a chain of electricity: the painted bolt, or (screen already full of effects) the cheap drawn one.
func lightning(from: Vector2, to: Vector2, color: Color) -> void:
	if _count <= BUSY_COUNT:
		sheet_stretch(EffectSheets.STORM_ARC, from, to, BOLT_HEIGHT)
		return
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
	_sheet[i] = null
	_seedv[i] = _next_seed()
	_follow[i] = follower
	if follower != null:
		_follow_last[i] = follower.global_position
	_count += 1


func _next_seed() -> float:
	_seed = (_seed + 1) % 997
	return float(_seed)


func _process(delta: float) -> void:
	if not _debug_shapes.is_empty() or show_shapes:
		for k in range(_debug_shapes.size() - 1, -1, -1):
			_debug_shapes[k][5] += delta
			if _debug_shapes[k][5] > DEBUG_SHAPE_LIFE:
				_debug_shapes.remove_at(k)
		queue_redraw()
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
	# The painted layer only exists while a SHEET effect plays (its material costs frames).
	var has_sheet := false
	var has_ground := false
	for i in _count:
		if _kind[i] == Kind.SHEET:
			if _style[i] == SheetMode.LOOP or _style[i] == SheetMode.GROUND:
				has_ground = true
				has_sheet = has_sheet or GROUND_FRONT_SHARE > 0.0
			else:
				has_sheet = true
	if has_sheet or _paint.visible:
		_paint.visible = has_sheet
		if has_sheet:
			_update_guard()
		_paint.queue_redraw()
	if has_ground or _ground.visible:
		_ground.visible = has_ground
		_ground.queue_redraw()


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
	_sheet[i] = _sheet[last]
	_sheet[last] = null
	_seedv[i] = _seedv[last]
	_follow[i] = _follow[last]
	_follow_last[i] = _follow_last[last]
	_follow[last] = null
	_count = last


func _draw() -> void:
	if not _debug_shapes.is_empty():
		_draw_debug_shapes()
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


## The painted layer: SHEET effects (EffectSheet frames, premultiplied alpha).
func _draw_paint() -> void:
	_draw_sheets(_paint, false)


## The ground layer: looping sheets (burning ground), under the creatures.
func _draw_ground() -> void:
	_draw_sheets(_ground, true)


func _draw_sheets(canvas: Node2D, ground: bool) -> void:
	for i in _count:
		if _kind[i] != Kind.SHEET:
			continue
		var is_loop := _style[i] == SheetMode.LOOP
		var on_ground := is_loop or _style[i] == SheetMode.GROUND
		if ground and not on_ground:
			continue
		if not ground and on_ground and GROUND_FRONT_SHARE <= 0.0:
			continue
		var t := _life[i] / _max_life[i]
		var effect := _sheet[i]
		if t > 1.0 or effect == null:
			continue
		var side := _size[i] * effect.scale
		var tall := side * effect.squash
		var progress := clampf(1.0 - t, 0.0, 1.0)
		var origin := _a[i] + _b[i] * (_size[i] * effect.forward)
		var rotation := _b[i].angle()
		match _style[i]:
			SheetMode.TRAVEL:
				origin += _b[i] * (_extra[i] * progress)
			SheetMode.STRETCH:
				side = _size[i] / maxf(effect.reach, 0.05)
				tall = _extra[i]
				origin = _a[i] + _b[i] * (_size[i] * 0.5)
			SheetMode.FALL:
				rotation = _b[i].angle() - effect.art_angle
				origin = _a[i] + _b[i] * (_extra[i] * progress) - effect.head.rotated(rotation) * side
			SheetMode.ORBIT:
				var around := rotation + progress * ORBIT_SWEEP
				origin = _a[i] + Vector2.from_angle(around) * _extra[i]
				rotation = around + PI * 0.5
		canvas.draw_set_transform(origin, rotation)
		var rect := Rect2(-side * 0.5, -tall * 0.5, side, tall)
		# Frames are cross-faded (premultiplied alpha: the weights scale color and alpha), so a
		# 12-frame painting plays as a smooth animation instead of a slideshow.
		var position := clampf(1.0 - t, 0.0, 0.999) * effect.frames
		var tint := _color[i] * effect.opacity * (GROUND_OPACITY if is_loop else PAINTED_OPACITY)
		if not is_loop:
			tint *= clampf(_life[i] / FADE_OUT, 0.0, 1.0)  # whole until the last moments
		if on_ground and not ground:
			tint *= GROUND_FRONT_SHARE  # the thin copy over the creatures
		var wrap := false
		if _style[i] == SheetMode.LOOP:
			position = fmod(progress * _extra[i], 1.0) * effect.frames
			tint *= clampf(progress / LOOP_FADE, 0.0, 1.0) * clampf(t / LOOP_FADE, 0.0, 1.0)
			wrap = true
		var first := int(position)
		var blend := position - first
		canvas.draw_texture_rect_region(effect.texture, rect, effect.frame_region(first), tint * (1.0 - blend))
		if wrap or first + 1 < effect.frames:
			canvas.draw_texture_rect_region(effect.texture, rect, effect.frame_region((first + 1) % effect.frames), tint * blend)
	canvas.draw_set_transform(Vector2.ZERO, 0.0)


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
