class_name DamageNumbers
extends Node2D
## Floating damage numbers in a fixed ring buffer, drawn by one canvas item.
## When full, the oldest number is overwritten (no allocation, bounded cost).

const CAPACITY := 160
const LIFE := 0.8
## Numbers rise fast then slow down: total rise distance over LIFE.
const RISE_DISTANCE := 56.0
const NORMAL_SIZE := 30
const CRIT_SIZE := 48
## Big hits get up to this much extra size (log scale from SIZE_REF_LOW to SIZE_REF_HIGH damage).
const BIG_HIT_BONUS := 0.3
const SIZE_REF_LOW := 10.0
const SIZE_REF_HIGH := 100.0
## Spawn "pop": start scaled up, ease back to 1.0 over POP_TIME.
const POP_TIME := 0.12
const POP_NORMAL := 1.6
const POP_CRIT := 2.0
const CRIT_SHAKE := 4.0
const FADE_TIME := 0.25
const NORMAL_COLOR := Color(1.0, 1.0, 1.0)
const CRIT_COLOR := Color(1.0, 0.75, 0.1)
const OUTLINE_SIZE := 7
const EMBOLDEN := 0.9
const BOX_WIDTH := 200.0
## Readability cap: at most this many new numbers per frame (crits have their own budget).
const MAX_NEW_PER_FRAME := 6

## Can be turned off (future settings menu).
var enabled: bool = true

var _pos := PackedVector2Array()
var _value := PackedFloat32Array()
var _crit := PackedByteArray()
var _life := PackedFloat32Array()
var _next: int = 0
var _visible_count: int = 0
var _spawned_this_frame: int = 0
var _crits_this_frame: int = 0
var _font: FontVariation


func _init() -> void:
	z_index = 20
	_pos.resize(CAPACITY)
	_value.resize(CAPACITY)
	_crit.resize(CAPACITY)
	_life.resize(CAPACITY)
	_font = UiTheme.font(700, true).duplicate() as FontVariation
	_font.variation_embolden = EMBOLDEN


## Font size for a hit: crits are bigger, big hits grow a little (capped).
static func font_size_for(value: float, crit: bool) -> int:
	var base := CRIT_SIZE if crit else NORMAL_SIZE
	var t := clampf(log(maxf(value, 1.0) / SIZE_REF_LOW) / log(SIZE_REF_HIGH / SIZE_REF_LOW), 0.0, 1.0)
	return roundi(base * (1.0 + BIG_HIT_BONUS * t))


## Scale multiplier at a given age (seconds since spawn): pops in large, eases out to 1.0.
static func pop_scale(age: float, crit: bool) -> float:
	var peak := POP_CRIT if crit else POP_NORMAL
	var t := clampf(age / POP_TIME, 0.0, 1.0)
	var ease_out := 1.0 - (1.0 - t) * (1.0 - t)
	return lerpf(peak, 1.0, ease_out)


func alive_count() -> int:
	var alive := 0
	for i in CAPACITY:
		if _life[i] > 0.0:
			alive += 1
	return alive


func spawn(pos: Vector2, value: float, crit: bool) -> void:
	if not enabled or value < 0.5:
		return
	if crit:
		if _crits_this_frame >= MAX_NEW_PER_FRAME:
			return
		_crits_this_frame += 1
	else:
		if _spawned_this_frame >= MAX_NEW_PER_FRAME:
			return
		_spawned_this_frame += 1
	_pos[_next] = pos + Vector2(randf_range(-10.0, 10.0), -12.0)
	_value[_next] = value
	_crit[_next] = 1 if crit else 0
	_life[_next] = LIFE
	_next = (_next + 1) % CAPACITY


func _process(delta: float) -> void:
	_spawned_this_frame = 0
	_crits_this_frame = 0
	var alive := 0
	for i in CAPACITY:
		if _life[i] > 0.0:
			_life[i] -= delta
			alive += 1
	if alive > 0 or _visible_count > 0:
		queue_redraw()
	_visible_count = alive


func _draw() -> void:
	var outline_color := Color(0, 0, 0)
	for i in CAPACITY:
		if _life[i] <= 0.0:
			continue
		var age := LIFE - _life[i]
		var crit := _crit[i] == 1
		var alpha := clampf(_life[i] / FADE_TIME, 0.0, 1.0)
		# Ease-out rise: fast at spawn, slowing down.
		var k := age / LIFE
		var rise := RISE_DISTANCE * (1.0 - (1.0 - k) * (1.0 - k))
		var at := _pos[i] + Vector2(0.0, -rise)
		if crit and age < POP_TIME:
			at.x += sin(age * 90.0) * CRIT_SHAKE * (1.0 - age / POP_TIME)
		var size := font_size_for(_value[i], crit)
		var color := CRIT_COLOR if crit else NORMAL_COLOR
		var text := str(maxi(1, roundi(_value[i])))
		var s := pop_scale(age, crit)
		# Scale around the number's anchor so the pop grows in place.
		draw_set_transform(at, 0.0, Vector2(s, s))
		var box := Vector2(-BOX_WIDTH * 0.5, size * 0.35)
		outline_color.a = alpha
		color.a = alpha
		draw_string_outline(_font, box, text, HORIZONTAL_ALIGNMENT_CENTER, BOX_WIDTH, size, OUTLINE_SIZE, outline_color)
		draw_string(_font, box, text, HORIZONTAL_ALIGNMENT_CENTER, BOX_WIDTH, size, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
