extends GutTest
## The boss bar shows one phase at a time: it refills at every phase.


func _boss(thresholds: Array[float]) -> EnemyData:
	var data := EnemyData.new()
	for ratio in thresholds:
		var phase := BossPhase.new()
		phase.hp_ratio = ratio
		data.phases.append(phase)
	return data


func test_segment_is_full_at_the_start_of_each_phase_and_empty_at_its_end() -> void:
	var data := _boss([1.0, 0.6, 0.3])
	assert_almost_eq(BossBar.segment_fill(data, 1.0), 1.0, 0.001)
	assert_almost_eq(BossBar.segment_fill(data, 0.8), 0.5, 0.001, "halfway through phase 1 (1.0 to 0.6)")
	assert_almost_eq(BossBar.segment_fill(data, 0.6), 1.0, 0.001, "phase 2 starts with a full bar")
	assert_almost_eq(BossBar.segment_fill(data, 0.45), 0.5, 0.001, "halfway through phase 2 (0.6 to 0.3)")
	assert_almost_eq(BossBar.segment_fill(data, 0.3), 1.0, 0.001, "phase 3 starts full")
	assert_almost_eq(BossBar.segment_fill(data, 0.0), 0.0, 0.001, "dead")


func test_a_boss_with_one_phase_shows_its_plain_ratio() -> void:
	var data := _boss([1.0])
	assert_almost_eq(BossBar.segment_fill(data, 0.4), 0.4, 0.001)


func test_title_shows_the_phase_only_for_multi_phase_bosses() -> void:
	var data := _boss([1.0, 0.5])
	data.name_key = "Boss"
	assert_eq(BossBar.phase_title(data, 1), "Boss  2/2")
	assert_eq(BossBar.phase_title(_boss([1.0]), 0), "")
