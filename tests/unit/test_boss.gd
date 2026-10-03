extends GutTest
## Bosses (ADR 0014): phases by HP, telegraphed patterns, director flow, rewards.

var _player: Player
var _enemies: EnemyManager
var _shots: EnemyProjectileManager
var _director: BossDirector
var _rng: RandomNumberGenerator


func before_each() -> void:
	var arena := Rect2(-1000, -1000, 2000, 2000)
	_player = Player.new()
	_player.setup(CharacterData.new(), arena)
	_player.invincible = true
	_player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(_player)
	_shots = EnemyProjectileManager.new()
	_shots.setup(Party.solo(_player), arena)
	add_child_autofree(_shots)
	_rng = RandomNumberGenerator.new()
	_rng.seed = 3
	_enemies = EnemyManager.new()
	_enemies.setup(Party.solo(_player), arena, 4, _rng, null, _shots)
	add_child_autofree(_enemies)
	_director = BossDirector.new()
	_director.setup(_enemies, _shots, Party.solo(_player), null, _rng)
	add_child_autofree(_director)


func _radial(count: int) -> RadialBurstPattern:
	var pattern := RadialBurstPattern.new()
	pattern.count = count
	pattern.windup = 0.5
	pattern.recovery = 0.5
	return pattern


func _boss(patterns: Array[BossPattern], second_phase: Array[BossPattern] = []) -> EnemyData:
	var data := EnemyData.new()
	data.id = &"test_boss"
	data.max_hp = 100.0
	data.speed = 0.0
	data.radius = 30.0
	var first := BossPhase.new()
	first.hp_ratio = 1.0
	first.patterns = patterns
	data.phases = [first]
	if not second_phase.is_empty():
		var second := BossPhase.new()
		second.hp_ratio = 0.5
		second.patterns = second_phase
		data.phases.append(second)
	return data


func test_phase_follows_hp_ratio() -> void:
	var data := _boss([_radial(4)], [_radial(8)])
	assert_eq(data.phase_index_for(1.0), 0)
	assert_eq(data.phase_index_for(0.51), 0)
	assert_eq(data.phase_index_for(0.5), 1)
	assert_eq(data.phase_index_for(0.1), 1)


func test_radial_burst_waits_for_the_windup_then_fires() -> void:
	watch_signals(_director)
	_enemies.spawn(_boss([_radial(12)]), Vector2(300, 0))
	assert_signal_emitted(_director, "boss_started")
	_director.update(0.3)
	assert_eq(_shots.active_count(), 0, "telegraph first")
	_director.update(0.3)
	assert_eq(_shots.active_count(), 12)


func test_repeats_fire_several_volleys() -> void:
	var pattern := _radial(6)
	pattern.repeats = 3
	pattern.repeat_interval = 0.2
	_enemies.spawn(_boss([pattern]), Vector2(300, 0))
	_director.update(0.5)
	for i in 3:
		_director.update(0.2)
	assert_eq(_shots.active_count(), 18)


func test_aimed_fan_points_at_the_player() -> void:
	var fan := AimedFanPattern.new()
	fan.count = 1
	fan.windup = 0.0
	var boss := _enemies.spawn(_boss([fan]), Vector2(400, 0))
	_director.update(0.01)
	assert_eq(_shots.active_count(), 1)
	var velocity: Vector2 = _shots._active[0].velocity
	assert_almost_eq(velocity.normalized().x, -1.0, 0.01, "towards the player at the origin")
	assert_true(boss.is_alive())


func test_dash_forces_the_boss_velocity() -> void:
	var dash := DashPattern.new()
	dash.windup = 0.2
	dash.dash_speed = 900.0
	dash.dash_duration = 0.4
	var boss := _enemies.spawn(_boss([dash]), Vector2(500, 0))
	_director.update(0.1)
	assert_eq(boss.forced_velocity, Vector2.ZERO, "stands still while telegraphing")
	assert_gt(boss.forced_time, 0.0)
	_director.update(0.15)
	assert_almost_eq(boss.forced_velocity.x, -900.0, 1.0)
	assert_almost_eq(boss.forced_time, 0.4, 0.001)


func test_summon_spawns_minions() -> void:
	var summon := SummonPattern.new()
	summon.windup = 0.0
	summon.count = 5
	summon.enemy = EnemyData.new()
	summon.enemy.max_hp = 5.0
	_enemies.spawn(_boss([summon]), Vector2(300, 0))
	_director.update(0.01)
	assert_eq(_enemies.active_count(), 6)


func test_phase_change_and_end_signals() -> void:
	watch_signals(_director)
	var boss := _enemies.spawn(_boss([_radial(4)], [_radial(8)]), Vector2(300, 0))
	_enemies.damage_enemy(0, 60.0, false, Vector2.ZERO, 0.0)
	_director.update(0.01)
	assert_signal_emitted_with_parameters(_director, "boss_phase_changed", [boss, 1])
	assert_almost_eq(boss.speed_multiplier, 1.0, 0.001)
	_enemies.damage_enemy(0, 100.0, false, Vector2.ZERO, 0.0)
	_director.update(0.01)
	assert_signal_emitted(_director, "boss_ended")
	assert_eq(_director.boss_count(), 0)


func test_enemies_without_phases_are_not_bosses() -> void:
	watch_signals(_director)
	var data := EnemyData.new()
	_enemies.spawn(data, Vector2(300, 0))
	assert_signal_not_emitted(_director, "boss_started")


func test_wave_event_picks_from_its_choices() -> void:
	var event := WaveEvent.new()
	var a := EnemyData.new()
	var b := EnemyData.new()
	event.enemy_choices = [a, b]
	var seen := {}
	for i in 30:
		seen[event.pick_enemy(_rng)] = true
	assert_eq(seen.size(), 2)
	var plain := WaveEvent.new()
	plain.enemy = a
	assert_eq(plain.pick_enemy(_rng), a)


func test_boss_bar_follows_the_director() -> void:
	var bar := BossBar.new()
	add_child_autofree(bar)
	bar.setup(_director)
	assert_false(bar.visible)
	var boss := _enemies.spawn(_boss([_radial(4)]), Vector2(300, 0))
	assert_true(bar.visible)
	boss.hp = 25.0
	bar._process(0.0)
	assert_almost_eq(bar._bar.value, 25.0, 0.01)
	_enemies.damage_enemy(0, 100.0, false, Vector2.ZERO, 0.0)
	_director.update(0.01)
	assert_false(bar.visible)


func test_reward_is_an_item_of_the_minimum_tier_that_can_be_owned() -> void:
	var low := ItemData.new()
	low.tier = 1
	var unique := ItemData.new()
	unique.tier = 3
	unique.max_count = 1
	var good := ItemData.new()
	good.tier = 2
	var inventory := Inventory.new(StatBlock.from_defaults())
	inventory.add(unique)
	var pool: Array[ItemData] = [low, unique, good]
	for i in 10:
		assert_eq(Run.pick_reward(pool, inventory, 2, _rng), good)
	assert_null(Run.pick_reward([low] as Array[ItemData], inventory, 2, _rng))
