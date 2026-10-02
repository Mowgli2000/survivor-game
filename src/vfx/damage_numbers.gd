class_name DamageNumbers
extends Node2D
## Floating damage numbers in a fixed ring buffer, drawn by one canvas item.
## When full, the oldest number is overwritten (no allocation, bounded cost).

const CAPACITY := 160
const LIFE := 0.6
const RISE_SPEED := 70.0
const NORMAL_SIZE := 22
const CRIT_SIZE := 32
const NORMAL_COLOR := Color(1.0, 1.0, 1.0)
const CRIT_COLOR := Color(1.0, 0.6, 0.2)
const BOX_WIDTH := 120.0
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


func _init() -> void:
	z_index = 20
	_pos.resize(CAPACITY)
	_value.resize(CAPACITY)
	_crit.resize(CAPACITY)
	_life.resize(CAPACITY)


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
	_pos[_next] = pos + Vector2(randf_range(-8.0, 8.0), -10.0)
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
			var p := _pos[i]
			p.y -= RISE_SPEED * delta
			_pos[i] = p
			alive += 1
	if alive > 0 or _visible_count > 0:
		queue_redraw()
	_visible_count = alive


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in CAPACITY:
		if _life[i] <= 0.0:
			continue
		var alpha := clampf(_life[i] / LIFE * 2.0, 0.0, 1.0)
		var crit := _crit[i] == 1
		var size := CRIT_SIZE if crit else NORMAL_SIZE
		var color := CRIT_COLOR if crit else NORMAL_COLOR
		var text := str(maxi(1, roundi(_value[i])))
		var at := _pos[i] - Vector2(BOX_WIDTH * 0.5, 0.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, BOX_WIDTH, size, 5, Color(0, 0, 0, alpha))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, BOX_WIDTH, size, Color(color, alpha))
