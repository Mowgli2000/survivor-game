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
	assert_almost_eq(stage.duration_at(1), 20.0, 0.001)
	assert_almost_eq(stage.duration_at(20), 60.0, 0.001)
	assert_almost_eq(stage.spawn_rate_at(1), 1.5, 0.001)
	assert_almost_eq(stage.spawn_rate_at(20), 20.0, 0.001)
	assert_almost_eq(stage.hp_multiplier_at(20), 5.0, 0.001)
	var mid := stage.duration_at(10)
	assert_gt(mid, 20.0)
	assert_lt(mid, 60.0)


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
