class_name BossDirector
extends Node
## Runs boss fights (ADR 0014): tracks every living enemy that has phases,
## picks the phase from its HP ratio and plays its patterns in a loop:
## telegraph (boss stands still) -> volleys -> recovery. Only a handful of
## bosses exist at once, so plain per-boss state is fine here.

signal boss_started(enemy: Enemy)
signal boss_phase_changed(enemy: Enemy, phase_index: int)
signal boss_ended(enemy: Enemy)

const PHASE_SHAKE := 0.45

enum Step { WINDUP, FIRING, RECOVERY }


class BossState:
	var enemy: Enemy
	var data: EnemyData
	var phase: int = 0
	var pattern_index: int = 0
	var step: Step = Step.WINDUP
	var timer: float = 0.0
	var volleys: int = 0
	var aim := Vector2.ZERO


var _ctx := BossContext.new()
var _stage: StageData
var _waves: WaveDirector
var _bosses: Array[BossState] = []


func setup(enemies: EnemyManager, enemy_projectiles: EnemyProjectileManager, party: Party,
		vfx: Vfx, rng: RandomNumberGenerator, stage: StageData = null, waves: WaveDirector = null) -> void:
	_ctx.enemies = enemies
	_ctx.enemy_projectiles = enemy_projectiles
	_ctx.party = party
	_ctx.vfx = vfx
	_ctx.rng = rng
	_stage = stage
	_waves = waves
	enemies.boss_spawned.connect(_on_boss_spawned)


func _ready() -> void:
	process_physics_priority = -5  # after EnemyManager (-10), before weapons


func boss_count() -> int:
	return _bosses.size()


func _physics_process(delta: float) -> void:
	update(delta)


func update(delta: float) -> void:
	for i in range(_bosses.size() - 1, -1, -1):
		var state := _bosses[i]
		var enemy := state.enemy
		if not enemy.is_alive() or enemy.data != state.data:
			_bosses.remove_at(i)
			enemy.forced_time = 0.0
			boss_ended.emit(enemy)
			continue
		if state.data.boss and not enemy.enraged and _waves != null and _waves.overtime > 0.0:
			_enrage(state)
		var phase := state.data.phase_index_for(enemy.hp / enemy.max_hp)
		if phase != state.phase:
			_enter_phase(state, phase)
		state.timer -= delta
		var guard := 0
		while state.timer <= 0.0 and guard < 8:
			guard += 1
			_advance(state)


## The boss goes berserk: red, harder hits, faster (a new phase keeps the speed bonus).
func _enrage(state: BossState) -> void:
	var enemy := state.enemy
	enemy.enraged = true
	enemy.damage_multiplier *= RAGE_DAMAGE
	enemy.speed_multiplier *= RAGE_SPEED
	enemy._refresh_tint()


func _on_boss_spawned(enemy: Enemy) -> void:
	var state := BossState.new()
	state.enemy = enemy
	state.data = enemy.data
	state.phase = enemy.data.phase_index_for(1.0)
	enemy.speed_multiplier = enemy.data.phases[state.phase].speed_multiplier
	_bosses.append(state)
	boss_started.emit(enemy)
	_start_pattern(state)


func _enter_phase(state: BossState, phase: int) -> void:
	state.phase = phase
	state.pattern_index = 0
	state.enemy.speed_multiplier = state.data.phases[phase].speed_multiplier * (RAGE_SPEED if state.enemy.enraged else 1.0)
	if _ctx.vfx != null:
		_ctx.vfx.explosion(state.enemy.position, state.enemy.radius * 4.0, state.data.color, false)
		_ctx.vfx.shake_requested.emit(PHASE_SHAKE)
	boss_phase_changed.emit(state.enemy, phase)
	_start_pattern(state)


func _pattern(state: BossState) -> BossPattern:
	var patterns := state.data.phases[state.phase].patterns
	return patterns[state.pattern_index % patterns.size()] if not patterns.is_empty() else null


func _start_pattern(state: BossState) -> void:
	var pattern := _pattern(state)
	state.step = Step.WINDUP
	state.volleys = 0
	if pattern == null:
		state.step = Step.RECOVERY
		state.timer = 1.0
		return
	_apply_pace()
	var windup := pattern.scaled_windup(_ctx)
	state.timer = windup
	# The attack frames: the strike frame (EnemyData.attack_strike_frame) lands as the windup ends.
	state.enemy.start_attack(windup / state.data.attack_strike_share())
	state.aim = _ctx.target_position(state.enemy.position)
	if windup > 0.0:
		state.enemy.forced_velocity = Vector2.ZERO
		state.enemy.forced_time = windup
	pattern.telegraph(_ctx, state.enemy, state.aim)


## Base pace of every boss fight (shorter dead time than the first data) and the seal's
## aggression on top: danger 1 is 0, danger 6 is 0.5.
const BASE_WINDUP := 0.85
const BASE_RECOVERY := 0.55
const BASE_SPEED := 1.1


## Past the clock the final boss rages: damage and speed up at once, the pace climbs to RAGE_AGGRESSION.
const RAGE_DAMAGE := 1.5
const RAGE_SPEED := 1.3
const RAGE_AGGRESSION := 0.9
const RAGE_RAMP := 60.0


func _apply_pace() -> void:
	var aggression := _stage.boss_aggression if _stage != null else 0.0
	if _waves != null and _waves.overtime > 0.0:
		aggression = lerpf(aggression, RAGE_AGGRESSION, clampf(_waves.overtime / RAGE_RAMP, 0.0, 1.0))
	_ctx.windup_scale = BASE_WINDUP * (1.0 - 0.4 * aggression)
	_ctx.recovery_scale = BASE_RECOVERY * (1.0 - aggression)
	_ctx.speed_scale = BASE_SPEED * (1.0 + 0.6 * aggression)


func _advance(state: BossState) -> void:
	var pattern := _pattern(state)
	if state.step == Step.RECOVERY or pattern == null:
		state.pattern_index += 1
		_start_pattern(state)
		return
	if _stage != null and _waves != null:
		_ctx.hp_multiplier = _stage.hp_multiplier_at(_waves.wave)
	pattern.fire(_ctx, state.enemy, state.aim, state.volleys)
	state.volleys += 1
	if state.volleys < pattern.repeats:
		state.step = Step.FIRING
		state.timer += pattern.repeat_interval
	else:
		state.step = Step.RECOVERY
		state.timer += pattern.recovery * _ctx.recovery_scale
