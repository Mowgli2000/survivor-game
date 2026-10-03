extends GutTest
## Waves: StageData curves and events, WaveDirector timing.


func _stage(wave_count: int) -> StageData:
	var stage := StageData.new()
	stage.wave_count = wave_count
	stage.duration_first = 20.0
	stage.duration_last = 60.0
	stage.spawn_rate_first = 1.5
	stage.spawn_rate_last = 20.0
	stage.hp_multiplier_first = 1.0
	stage.hp_multiplier_last = 5.0
	return stage


func _event(wave: int, at_time: float) -> WaveEvent:
	var event := WaveEvent.new()
	event.wave = wave
	event.at_time = at_time
	event.enemy = EnemyData.new()
	event.count = 3
	return event


func test_curves_interpolate_from_first_to_last_wave() -> void:
	var stage := _stage(20)
	assert_almost_eq(stage.spawn_rate_at(1), 1.5, 0.001)
	assert_almost_eq(stage.spawn_rate_at(20), 20.0, 0.001)
	assert_almost_eq(stage.hp_multiplier_at(20), 5.0, 0.001)


func test_hp_curve_ramps_up_late() -> void:
	var stage := _stage(21)  # t = (wave - 1) / 20
	stage.hp_multiplier_curve = 2.0
	assert_almost_eq(stage.hp_multiplier_at(1), 1.0, 0.001)
	assert_almost_eq(stage.hp_multiplier_at(11), 1.0 + 4.0 * 0.25, 0.001, "t = 0.5 -> 0.25 of the way")
	assert_almost_eq(stage.hp_multiplier_at(21), 5.0, 0.001)


func test_durations_step_up_to_the_cap() -> void:
	var stage := _stage(20)
	assert_almost_eq(stage.duration_at(1), 20.0, 0.001)
	assert_almost_eq(stage.duration_at(2), 25.0, 0.001)
	assert_almost_eq(stage.duration_at(8), 55.0, 0.001)
	assert_almost_eq(stage.duration_at(9), 60.0, 0.001)
	assert_almost_eq(stage.duration_at(20), 60.0, 0.001, "no final duration set")


func test_final_wave_has_its_own_duration() -> void:
	var stage := _stage(20)
	stage.final_wave_duration = 90.0
	assert_almost_eq(stage.duration_at(19), 60.0, 0.001)
	assert_almost_eq(stage.duration_at(20), 90.0, 0.001)


func test_curves_with_a_single_wave_use_first_values() -> void:
	var stage := _stage(1)
	assert_almost_eq(stage.duration_at(1), 20.0, 0.001)
	assert_almost_eq(stage.t_at(1), 0.0, 0.001)


func test_curves_clamp_out_of_range_waves() -> void:
	var stage := _stage(20)
	assert_almost_eq(stage.duration_at(0), 20.0, 0.001)
	assert_almost_eq(stage.duration_at(25), 60.0, 0.001)


func test_events_for_returns_only_that_wave() -> void:
	var stage := _stage(20)
	stage.events = [_event(5, 1.0), _event(8, 2.0), _event(5, 4.0)]
	assert_eq(stage.events_for(5).size(), 2)
	assert_eq(stage.events_for(8).size(), 1)
	assert_eq(stage.events_for(1).size(), 0)


func _director(wave_count: int) -> WaveDirector:
	var director := WaveDirector.new()
	director.setup(_stage(wave_count))
	add_child_autofree(director)
	return director


func test_wave_counts_down_and_ends() -> void:
	var director := _director(3)
	watch_signals(director)
	director.start_wave(1)
	assert_signal_emitted_with_parameters(director, "wave_started", [1])
	assert_true(director.in_wave)
	assert_almost_eq(director.time_left, 20.0, 0.001)
	director.time_left = 0.01
	await wait_physics_frames(2)
	assert_signal_emitted_with_parameters(director, "wave_ended", [1])
	assert_false(director.in_wave)
	assert_signal_not_emitted(director, "run_won")


func test_next_wave_never_starts_by_itself() -> void:
	var director := _director(3)
	director.start_wave(1)
	director.time_left = 0.01
	await wait_physics_frames(5)
	assert_eq(director.wave, 1)
	assert_false(director.in_wave)


func test_last_wave_emits_run_won() -> void:
	var director := _director(3)
	watch_signals(director)
	director.start_wave(3)
	assert_true(director.is_last_wave())
	director.time_left = 0.01
	await wait_physics_frames(2)
	assert_signal_emitted(director, "wave_ended")
	assert_signal_emit_count(director, "run_won", 1)


func test_wave_elapsed() -> void:
	var director := _director(3)
	director.start_wave(1)
	director.time_left = 15.0
	assert_almost_eq(director.wave_elapsed(), 5.0, 0.001)


func test_collect_all_returns_total_xp() -> void:
	var player := Player.new()
	player.setup(CharacterData.new(), Rect2(-1000, -1000, 2000, 2000))
	player.invincible = true
	player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(player)
	var pickups := PickupManager.new()
	pickups.setup(player, 2)  # tiny cap: extra gems get merged
	add_child_autofree(pickups)
	watch_signals(pickups)
	pickups.spawn_xp(Vector2(900, 900), 3)
	pickups.spawn_xp(Vector2(-900, 900), 4)
	pickups.spawn_xp(Vector2(900, -900), 5)  # merged into an existing gem
	pickups.collect_all()
	assert_eq(pickups.active_count(), 0)
	assert_signal_emit_count(pickups, "xp_collected", 1)
	assert_signal_emitted_with_parameters(pickups, "xp_collected", [12])


func _spawn_setup(stage: StageData) -> Array:
	var arena := Rect2(-3000, -3000, 6000, 6000)
	var player := Player.new()
	player.setup(CharacterData.new(), arena)
	player.invincible = true
	player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(player)
	var enemies := EnemyManager.new()
	enemies.setup(player, arena, 8)
	add_child_autofree(enemies)
	var director := WaveDirector.new()
	director.setup(stage)
	add_child_autofree(director)
	var spawner := SpawnDirector.new()
	var state := RunState.new(1)
	spawner.setup(stage, state, enemies, player, arena, director)
	add_child_autofree(spawner)
	return [director, spawner, enemies, state]


func test_wave_event_spawns_once_at_its_time() -> void:
	var stage := _stage(3)
	stage.spawn_rate_first = 0.0
	stage.spawn_rate_last = 0.0
	var event := _event(1, 0.0)
	event.elite = true
	stage.events = [event]
	var parts := _spawn_setup(stage)
	var director: WaveDirector = parts[0]
	var spawner: SpawnDirector = parts[1]
	var enemies: EnemyManager = parts[2]
	director.start_wave(1)
	spawner.begin_wave(1)
	await wait_physics_frames(3)
	assert_eq(enemies.active_count(), 3)
	assert_true(enemies.get_enemy(0).elite)
	await wait_physics_frames(3)
	assert_eq(enemies.active_count(), 3, "an event fires only once")


func test_spawn_pool_respects_min_wave() -> void:
	var stage := _stage(10)
	stage.spawn_rate_first = 60.0
	stage.spawn_rate_last = 60.0
	var early := SpawnEntry.new()
	early.enemy = EnemyData.new()
	early.min_wave = 1
	var late := SpawnEntry.new()
	late.enemy = EnemyData.new()
	late.min_wave = 5
	stage.spawn_pool = [early, late]
	var parts := _spawn_setup(stage)
	var director: WaveDirector = parts[0]
	var spawner: SpawnDirector = parts[1]
	var enemies: EnemyManager = parts[2]
	director.start_wave(1)
	spawner.begin_wave(1)
	await wait_physics_frames(30)
	assert_gt(enemies.active_count(), 0)
	for i in enemies.active_count():
		assert_eq(enemies.get_enemy(i).data, early.enemy, "wave 1 only spawns early enemies")


func test_no_spawn_between_waves() -> void:
	var stage := _stage(3)
	stage.spawn_rate_first = 60.0
	stage.spawn_rate_last = 60.0
	var entry := SpawnEntry.new()
	entry.enemy = EnemyData.new()
	stage.spawn_pool = [entry]
	var parts := _spawn_setup(stage)
	var enemies: EnemyManager = parts[2]
	await wait_physics_frames(30)  # no wave started
	assert_eq(enemies.active_count(), 0)


func test_wave_event_ignores_the_enemy_cap() -> void:
	var stage := _stage(3)
	stage.spawn_rate_first = 0.0
	stage.spawn_rate_last = 0.0
	stage.max_enemies = 2
	stage.events = [_event(1, 0.0)]
	var parts := _spawn_setup(stage)
	var director: WaveDirector = parts[0]
	var spawner: SpawnDirector = parts[1]
	var enemies: EnemyManager = parts[2]
	director.start_wave(1)
	spawner.begin_wave(1)
	await wait_physics_frames(3)
	assert_eq(enemies.active_count(), 3, "scripted events (elites, hordes) are never cut by the cap")


func test_finish_wave_ends_it_on_next_frame() -> void:
	var director := _director(3)
	watch_signals(director)
	director.start_wave(3)
	director.finish_wave()
	await wait_physics_frames(2)
	assert_signal_emitted_with_parameters(director, "wave_ended", [3])
	assert_signal_emit_count(director, "run_won", 1)


func test_spawner_counts_wave_spawns() -> void:
	var stage := _stage(3)
	stage.spawn_rate_first = 0.0
	stage.spawn_rate_last = 0.0
	stage.events = [_event(1, 0.0)]
	var parts := _spawn_setup(stage)
	var director: WaveDirector = parts[0]
	var spawner: SpawnDirector = parts[1]
	var state: RunState = parts[3]
	state.wave_spawned = 99
	director.start_wave(1)
	spawner.begin_wave(1)
	assert_eq(state.wave_spawned, 0, "counters reset at wave start")
	await wait_physics_frames(3)
	assert_eq(state.wave_spawned, 3)


func test_has_living_boss() -> void:
	var parts := _spawn_setup(_stage(3))
	var enemies: EnemyManager = parts[2]
	var boss_data := EnemyData.new()
	boss_data.boss = true
	enemies.spawn(EnemyData.new(), Vector2(500, 0))
	assert_false(enemies.has_living_boss())
	var boss := enemies.spawn(boss_data, Vector2(-500, 0))
	assert_true(enemies.has_living_boss())
	boss.hp = 0.0
	assert_false(enemies.has_living_boss(), "a dead boss does not count")


func test_spawn_rate_curve_ramps_up_late() -> void:
	var stage := _stage(20)
	stage.spawn_rate_last = 24.0
	stage.spawn_rate_curve = 1.8
	assert_almost_eq(stage.spawn_rate_at(1), 1.5, 0.001)
	assert_almost_eq(stage.spawn_rate_at(20), 24.0, 0.001)
	assert_lt(stage.spawn_rate_at(5), 3.5, "early waves barely change")
	assert_gt(stage.spawn_rate_at(15), 13.0, "late waves get crowded")


func test_material_rate_drops_over_the_run() -> void:
	var stage := _stage(20)
	stage.material_rate_first = 1.0
	stage.material_rate_last = 0.6
	assert_almost_eq(stage.material_rate_at(1), 1.0, 0.001)
	assert_almost_eq(stage.material_rate_at(20), 0.6, 0.001)


func test_materials_per_second_stay_flat_when_fully_decoupled() -> void:
	var stage := _stage(20)
	stage.spawn_rate_first = 10.0
	stage.spawn_rate_last = 40.0
	stage.material_reference_spawn_rate = 10.0
	stage.material_decoupling = 1.0
	assert_almost_eq(stage.material_rate_at(1), 1.0, 0.001, "below the reference: unchanged")
	assert_almost_eq(stage.material_rate_at(20) * 40.0, 10.0, 0.001, "4x enemies, same materials/s")
	stage.material_decoupling = 0.5
	assert_almost_eq(stage.material_rate_at(20), 0.5, 0.001, "half decoupled: sqrt(10/40)")


func test_damage_and_group_curves() -> void:
	var stage := _stage(21)  # t = (wave - 1) / 20
	stage.damage_multiplier_last = 3.0
	stage.damage_multiplier_curve = 2.0
	stage.group_size_last = 11
	assert_almost_eq(stage.damage_multiplier_at(1), 1.0, 0.001)
	assert_almost_eq(stage.damage_multiplier_at(11), 1.5, 0.001)
	assert_almost_eq(stage.damage_multiplier_at(21), 3.0, 0.001)
	assert_eq(stage.group_size_at(1), 1)
	assert_eq(stage.group_size_at(11), 6)
	assert_eq(stage.group_size_at(21), 11)


func test_steady_spawns_arrive_in_groups() -> void:
	var stage := _stage(3)
	stage.spawn_rate_first = 120.0
	stage.spawn_rate_last = 120.0
	stage.group_size_first = 6
	stage.group_size_last = 6
	var entry := SpawnEntry.new()
	entry.enemy = EnemyData.new()
	stage.spawn_pool = [entry]
	var parts := _spawn_setup(stage)
	var director: WaveDirector = parts[0]
	var spawner: SpawnDirector = parts[1]
	var enemies: EnemyManager = parts[2]
	director.start_wave(1)
	spawner.begin_wave(1)
	await wait_physics_frames(4)
	assert_eq(enemies.active_count() % 6, 0, "whole groups only")
	assert_gt(enemies.active_count(), 0)
	# A group spawns close together.
	var first := enemies.get_enemy(0).position
	for i in range(1, 6):
		assert_lt(enemies.get_enemy(i).position.distance_to(first), SpawnDirector.GROUP_SPREAD * 2.0 + 1.0)
