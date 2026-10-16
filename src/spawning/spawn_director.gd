class_name SpawnDirector
extends Node
## Decides when, what and where enemies spawn during a wave: a steady rate
## from the stage curves, arriving in groups that rush in from one side (bigger
## late in the run), plus the scripted events of the wave (hordes, elites).
## Does nothing between waves.

const POSITION_ATTEMPTS := 8
## Members of a group appear within this distance of the group's center.
const GROUP_SPREAD := 90.0
## Boss duel: no steady spawn while the final boss lives, however long it takes (the wave only ends when it
## dies). A mini-boss keeps MINI_BOSS_FLOW of the flow; after BOSS_PAUSE seconds of fight the flow comes back
## over BOSS_RAMP seconds, so a fight nobody can finish is not a free rest.
const BOSS_PAUSE := 45.0
const BOSS_RAMP := 30.0
## During a mini-boss fight (phases, `boss = false`) this share of the steady flow stays: gold to
## collect and a crowd around the duel. Only the final boss clears the arena.
const MINI_BOSS_FLOW := 0.4
## A boss with an entrance animation appears this far from the players (on screen), at least this far from the walls.
const ENTRANCE_DISTANCE := 420.0
const ENTRANCE_MARGIN := 120.0
const BOSS_POLL := 0.5

var _stage: StageData
var _state: RunState
var _enemies: EnemyManager
var _party: Party
var _arena: Rect2
var _waves: WaveDirector
var _wave: int = 0
var _accumulator: float = 0.0
var _weights := PackedFloat32Array()
var _eligible: Array[EnemyData] = []
var _pending_events: Array[WaveEvent] = []
## Seconds since the first boss of the wave appeared; -1 when no fight is on.
var _boss_clock: float = -1.0
## True while the living phased enemies are mini-bosses only (refreshed by the poll).
var _mini_only: bool = false
var _boss_poll: float = 0.0


func setup(stage: StageData, state: RunState, enemies: EnemyManager, party: Party, arena: Rect2,
		waves: WaveDirector) -> void:
	_stage = stage
	_state = state
	_enemies = enemies
	_party = party
	_arena = arena
	_waves = waves
	enemies.boss_spawned.connect(_on_boss_spawned)


func _ready() -> void:
	process_physics_priority = -20


## Called when a wave starts: picks the eligible enemies and the wave's events.
func begin_wave(wave: int) -> void:
	_wave = wave
	_accumulator = 0.0
	_boss_clock = -1.0
	_state.wave_spawned = 0
	_state.wave_kills = 0
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
	var damage_multiplier := _stage.damage_multiplier_at(_wave)
	_fire_events(_waves.wave_elapsed(), hp_multiplier, damage_multiplier)
	var flow := 0.0 if _waves.pending_reward else _boss_flow(delta)  # the final boss is dead, its chest waits: quiet
	_accumulator += _stage.spawn_rate_at(_wave) * delta * flow
	var group := _stage.group_size_at(_wave)
	while _accumulator >= group:
		_accumulator -= group
		if _enemies.active_count() + group > _stage.max_enemies:
			_accumulator = 0.0
			break
		var center := _pick_position()
		for k in group:
			var index := WeightedPicker.pick_index(_weights, _state.rng)
			if index < 0:
				return
			var jitter := Vector2.from_angle(_state.rng.randf() * TAU) * _state.rng.randf() * GROUP_SPREAD
			var elite_chance := _stage.steady_elite_chance_at(_wave)
			var elite := elite_chance > 0.0 and _state.rng.randf() < elite_chance
			_enemies.spawn(_eligible[index], (center + jitter).clamp(_arena.position, _arena.end),
				hp_multiplier * (_stage.elite_hp_multiplier if elite else 1.0), elite, damage_multiplier)
			_state.wave_spawned += 1


func _on_boss_spawned(enemy: Enemy) -> void:
	if _boss_clock < 0.0:
		_boss_clock = 0.0
		_boss_poll = BOSS_POLL
		_mini_only = true
	if enemy.data.boss:
		_mini_only = false


## Share (0..1) of the steady spawn flow right now: 1 outside a boss fight, 0 during the duel, then back up.
func _boss_flow(delta: float) -> float:
	if _boss_clock < 0.0:
		return 1.0
	_boss_clock += delta
	_boss_poll -= delta
	if _boss_poll <= 0.0:
		_boss_poll = BOSS_POLL
		if not _enemies.has_living_phased():
			_boss_clock = -1.0
			return 1.0
		_mini_only = not _enemies.has_living_boss()
	if not _mini_only:
		return 0.0  # the final boss is a duel: nobody else comes until it is dead
	var ramp := clampf((_boss_clock - BOSS_PAUSE) / BOSS_RAMP, 0.0, 1.0)
	return maxf(ramp, MINI_BOSS_FLOW)


func _fire_events(elapsed: float, hp_multiplier: float, damage_multiplier: float) -> void:
	for i in range(_pending_events.size() - 1, -1, -1):
		var event := _pending_events[i]
		if elapsed < event.at_time:
			continue
		_pending_events.remove_at(i)
		var hp := hp_multiplier * (_stage.elite_hp_multiplier if event.elite else 1.0)
		var offset := _state.rng.randf() * TAU
		var enemy := event.pick_enemy(_state.rng)
		if enemy.boss or not enemy.phases.is_empty():
			hp *= _stage.boss_hp_share
		# Scripted events ignore max_enemies: elites and hordes must always appear.
		for k in event.count:
			var angle := offset + TAU * k / event.count
			var pos := _party.center() + Vector2.from_angle(angle) * _stage.spawn_distance
			if enemy.attack_sheet != null and enemy.attack_sheet.has_animation(&"entrance"):
				pos = _entrance_spot(angle)
			_enemies.spawn(enemy, pos.clamp(_arena.position, _arena.end), hp, event.elite,
				damage_multiplier)
		_state.wave_spawned += event.count


## Where a boss with an entrance animation appears: in view of the players, so the entrance is seen. Starts
## from `angle` and turns until the spot is inside the arena (a wall behind the players, say).
func _entrance_spot(angle: float) -> Vector2:
	var center := _party.center()
	var inside := _arena.grow(-ENTRANCE_MARGIN)
	for step in 12:
		var spot := center + Vector2.from_angle(angle + TAU * step / 12.0) * ENTRANCE_DISTANCE
		if inside.has_point(spot):
			return spot
	return (center + Vector2.from_angle(angle) * ENTRANCE_DISTANCE).clamp(inside.position, inside.end)


## A point at `spawn_distance` from the players' center, inside the arena when possible.
func _pick_position() -> Vector2:
	var center := _party.center()
	var fallback := center
	for attempt in POSITION_ATTEMPTS:
		var pos := center + Vector2.from_angle(_state.rng.randf() * TAU) * _stage.spawn_distance
		if _arena.has_point(pos):
			return pos
		fallback = pos
	return fallback.clamp(_arena.position, _arena.end)
