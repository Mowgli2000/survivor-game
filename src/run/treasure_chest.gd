class_name TreasureChest
extends Node2D
## A boss's treasure chest: it drops where the boss died and waits, glowing, until a player walks onto
## it; then the opening animation plays (the reward comes with the burst of light), and it fades away.
## `opened` is emitted when the reward is given (the burst), `finished` when the animation is over.

signal opened
signal finished

enum State { DROPPING, WAITING, OPENING, OPEN }

const DROP_TIME := 0.55
const DROP_HEIGHT := 260.0
const FADE_TIME := 1.4
const GOLD := Color(1.0, 0.82, 0.3)

var state: State = State.DROPPING

var _data: ChestData
var _party: Party
var _time: float = 0.0
var _frame: int = 0
var _burst_done := false


static func create(data: ChestData, party: Party, pos: Vector2) -> TreasureChest:
	var chest := TreasureChest.new()
	chest._data = data
	chest._party = party
	chest.position = pos
	chest.z_index = 2
	return chest


func _physics_process(delta: float) -> void:
	_time += delta
	match state:
		State.DROPPING:
			if _time >= DROP_TIME:
				state = State.WAITING
				_time = 0.0
		State.WAITING:
			if _player_close():
				open()
		State.OPENING:
			var frames := _frames()
			_frame = mini(int(_time * _data.open_fps), frames - 1)
			if not _burst_done and _frame >= _data.burst_frame:
				_burst_done = true
				opened.emit()
			if _frame >= frames - 1 and _time >= frames / _data.open_fps:
				state = State.OPEN
				_time = 0.0
				finished.emit()
		State.OPEN:
			if _time >= FADE_TIME:
				queue_free()
	queue_redraw()


## Starts the opening (a player walked on it, or the wave ended before anyone did).
func open() -> void:
	if state == State.OPENING or state == State.OPEN:
		return
	state = State.OPENING
	_time = 0.0
	_frame = 0


## Skips the animation: the reward is given now (the wave is over, the chest is swept up).
func open_now() -> void:
	if state == State.OPEN:
		return
	if not _burst_done:
		_burst_done = true
		opened.emit()
	state = State.OPEN
	_time = FADE_TIME
	finished.emit()


func _player_close() -> bool:
	for player in _party.members:
		if not player.is_dead and player.global_position.distance_to(global_position) <= _data.open_radius:
			return true
	return false


func _frames() -> int:
	return maxi(_data.sheet.animations[&"open"].y, 1)


func _draw() -> void:
	if _data == null or _data.sheet == null:
		return
	var first: int = _data.sheet.animations[&"open"].x
	var drop := 0.0
	var alpha := 1.0
	match state:
		State.DROPPING:
			var t := clampf(_time / DROP_TIME, 0.0, 1.0)
			drop = -DROP_HEIGHT * (1.0 - t) * (1.0 - t)
			alpha = clampf(t * 3.0, 0.0, 1.0)
		State.OPEN:
			alpha = 1.0 - clampf(_time / FADE_TIME, 0.0, 1.0)
	if state == State.WAITING:
		_draw_beacon()
	var frame := first + (_frame if state == State.OPENING or state == State.OPEN else 0)
	if state == State.OPEN:
		frame = first + _frames() - 1
	var shown := Rect2(-_data.sheet.cell_size.x * _data.height / _data.sheet.cell_size.y * 0.5, drop - _data.height,
		_data.sheet.cell_size.x * _data.height / _data.sheet.cell_size.y, _data.height)
	draw_texture_rect_region(_data.sheet.texture, shown, _data.sheet.region(frame), Color(1, 1, 1, alpha))


## A pulsing golden ring on the ground and a bobbing arrow: "walk on it".
func _draw_beacon() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	draw_arc(Vector2.ZERO, _data.open_radius * (0.8 + 0.1 * pulse), 0.0, TAU, 48, Color(GOLD, 0.35 + 0.35 * pulse), 4.0)
	var top := -_data.height - 14.0 + 8.0 * sin(_time * 5.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, top - 22), Vector2(16, top - 22), Vector2(0, top)]), Color(GOLD, 0.9))
