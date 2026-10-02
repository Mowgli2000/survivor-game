class_name PickupManager
extends Node2D
## Owns XP gems: magnet attraction toward the player and collection.
## Above `max_gems`, new XP is merged into existing gems to cap the entity count.

signal xp_collected(amount: int)

const ATTRACT_START_SPEED := 150.0
const ATTRACT_ACCELERATION := 1500.0

var _player: Player
var _max_gems: int = 300
var _active: Array[XpGem] = []
var _pool: ObjectPool
var _merge_cursor: int = 0
## Physics frame of the last pickup sound request.
var _sound_frame: int = -1


func setup(player: Player, max_gems: int) -> void:
	_player = player
	_max_gems = max_gems
	_pool = ObjectPool.new(_create_gem)


func _ready() -> void:
	process_physics_priority = 20
	z_index = -1


func spawn_xp(pos: Vector2, value: int) -> void:
	if _active.size() >= _max_gems:
		_merge_cursor = (_merge_cursor + 1) % _active.size()
		_active[_merge_cursor].add_value(value)
		return
	var gem: XpGem = _pool.acquire()
	gem.reset(pos, value)
	_active.append(gem)


## Collects every gem at once (end of wave): a single xp_collected with the total.
func collect_all() -> void:
	var total := 0
	for gem in _active:
		total += gem.value
		gem.visible = false
		_pool.release(gem)
	_active.clear()
	if total > 0:
		xp_collected.emit(total)


func active_count() -> int:
	return _active.size()


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var player_pos := _player.global_position
	var pickup_range := _player.stats.get_value(StatIds.PICKUP_RANGE)
	var pickup_r2 := pickup_range * pickup_range
	var collect_dist := _player.radius + XpGem.SIZE
	var collect_r2 := collect_dist * collect_dist
	for i in range(_active.size() - 1, -1, -1):
		var gem := _active[i]
		var d2 := gem.position.distance_squared_to(player_pos)
		if not gem.attracted and d2 <= pickup_r2:
			gem.attracted = true
			gem.speed = ATTRACT_START_SPEED
		if gem.attracted:
			gem.speed += ATTRACT_ACCELERATION * delta
			gem.position = gem.position.move_toward(player_pos, gem.speed * delta)
			d2 = gem.position.distance_squared_to(player_pos)
		if d2 <= collect_r2:
			var value := gem.value
			gem.visible = false
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			_pool.release(gem)
			xp_collected.emit(value)
			if Engine.get_physics_frames() != _sound_frame:
				_sound_frame = Engine.get_physics_frames()
				Audio.play(Sounds.PICKUP, -16.0, 0.15)


func _create_gem() -> XpGem:
	var gem := XpGem.new()
	gem.visible = false
	add_child(gem)
	return gem
