class_name SpawnDirector
extends Node
## Decides when, what and where enemies spawn. Prototype version: a spawn rate
## that grows with time. Waves (StageData) will replace the rate curve later.

const POSITION_ATTEMPTS := 8

var _config: RunConfig
var _state: RunState
var _enemies: EnemyManager
var _player: Player
var _arena: Rect2
var _accumulator: float = 0.0
var _weights := PackedFloat32Array()
var _eligible: Array[EnemyData] = []


func setup(config: RunConfig, state: RunState, enemies: EnemyManager, player: Player, arena: Rect2) -> void:
	_config = config
	_state = state
	_enemies = enemies
	_player = player
	_arena = arena


func _ready() -> void:
	process_physics_priority = -20


func current_spawn_rate() -> float:
	var minutes := _state.elapsed / 60.0
	return minf(_config.spawn_rate_start + _config.spawn_rate_per_minute * minutes, _config.spawn_rate_max)


func current_hp_multiplier() -> float:
	return _config.enemy_hp_multiplier + _config.enemy_hp_per_minute * _state.elapsed / 60.0


func _physics_process(delta: float) -> void:
	if _config == null:
		return
	_accumulator += current_spawn_rate() * delta
	if _accumulator < 1.0:
		return
	_refresh_eligible()
	var hp_multiplier := current_hp_multiplier()
	while _accumulator >= 1.0:
		_accumulator -= 1.0
		if _enemies.active_count() >= _config.max_enemies:
			_accumulator = 0.0
			break
		var index := WeightedPicker.pick_index(_weights, _state.rng)
		if index < 0:
			break
		_enemies.spawn(_eligible[index], _pick_position(), hp_multiplier)


func _refresh_eligible() -> void:
	_eligible.clear()
	_weights.clear()
	for entry in _config.spawn_pool:
		if entry.enemy != null and _state.elapsed >= entry.min_time:
			_eligible.append(entry.enemy)
			_weights.append(entry.weight)


## A point at `spawn_distance` from the player, inside the arena when possible.
func _pick_position() -> Vector2:
	var center := _player.global_position
	var fallback := center
	for attempt in POSITION_ATTEMPTS:
		var pos := center + Vector2.from_angle(_state.rng.randf() * TAU) * _config.spawn_distance
		if _arena.has_point(pos):
			return pos
		fallback = pos
	return fallback.clamp(_arena.position, _arena.end)
