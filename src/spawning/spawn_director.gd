class_name SpawnDirector
extends Node
## Decides when, what and where enemies spawn during a wave: a steady rate
## from the stage curves, plus the scripted events of the wave (hordes, elites).
## Does nothing between waves.

const POSITION_ATTEMPTS := 8

var _stage: StageData
var _state: RunState
var _enemies: EnemyManager
var _player: Player
var _arena: Rect2
var _waves: WaveDirector
var _wave: int = 0
var _accumulator: float = 0.0
var _weights := PackedFloat32Array()
var _eligible: Array[EnemyData] = []
var _pending_events: Array[WaveEvent] = []


func setup(stage: StageData, state: RunState, enemies: EnemyManager, player: Player, arena: Rect2,
		waves: WaveDirector) -> void:
	_stage = stage
	_state = state
	_enemies = enemies
	_player = player
	_arena = arena
	_waves = waves


func _ready() -> void:
	process_physics_priority = -20


## Called when a wave starts: picks the eligible enemies and the wave's events.
func begin_wave(wave: int) -> void:
	_wave = wave
	_accumulator = 0.0
	_pending_events = _stage.events_for(wave)
	_eligible.clear()
	_weights.clear()
	for entry in _stage.spawn_pool:
		if entry.enemy != null and entry.min_wave <= wave:
			_eligible.append(entry.enemy)
			_weights.append(entry.weight)


func _physics_process(delta: float) -> void:
	if _stage == null or not _waves.in_wave or _wave != _waves.wave:
		return
	var hp_multiplier := _stage.hp_multiplier_at(_wave)
	_fire_events(_waves.wave_elapsed(), hp_multiplier)
	_accumulator += _stage.spawn_rate_at(_wave) * delta
	while _accumulator >= 1.0:
		_accumulator -= 1.0
		if _enemies.active_count() >= _stage.max_enemies:
			_accumulator = 0.0
			break
		var index := WeightedPicker.pick_index(_weights, _state.rng)
		if index < 0:
			break
		_enemies.spawn(_eligible[index], _pick_position(), hp_multiplier)


func _fire_events(elapsed: float, hp_multiplier: float) -> void:
	for i in range(_pending_events.size() - 1, -1, -1):
		var event := _pending_events[i]
		if elapsed < event.at_time:
			continue
		_pending_events.remove_at(i)
		var hp := hp_multiplier * (_stage.elite_hp_multiplier if event.elite else 1.0)
		var offset := _state.rng.randf() * TAU
		# Scripted events ignore max_enemies: elites and hordes must always appear.
		for k in event.count:
			var angle := offset + TAU * k / event.count
			var pos := _player.global_position + Vector2.from_angle(angle) * _stage.spawn_distance
			_enemies.spawn(event.enemy, pos.clamp(_arena.position, _arena.end), hp, event.elite)


## A point at `spawn_distance` from the player, inside the arena when possible.
func _pick_position() -> Vector2:
	var center := _player.global_position
	var fallback := center
	for attempt in POSITION_ATTEMPTS:
		var pos := center + Vector2.from_angle(_state.rng.randf() * TAU) * _stage.spawn_distance
		if _arena.has_point(pos):
			return pos
		fallback = pos
	return fallback.clamp(_arena.position, _arena.end)
