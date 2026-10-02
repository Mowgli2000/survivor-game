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
