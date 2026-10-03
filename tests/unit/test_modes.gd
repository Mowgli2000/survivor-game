extends GutTest
## Difficulty levels and endless mode (step 7b).

const RUN := preload("res://src/run/run.tscn")


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.TEST_PATH))
	SaveService.load_profile()


func _stage() -> StageData:
	return (ContentDB.get_def(&"runs", &"default") as RunConfig).stage


func _danger(level: int) -> DifficultyData:
	return ContentDB.get_def(&"difficulties", StringName("danger_%d" % level))


func test_copy_is_independent_and_keeps_shared_enemies() -> void:
	var original := _stage()
	var copy := original.copy()
	copy.events[0].count += 100
	copy.endless = true
	assert_ne(original.events[0].count, copy.events[0].count)
	assert_false(original.endless)
	assert_eq(copy.events[0].enemy, original.events[0].enemy, "enemy definitions stay shared")


func test_difficulty_scales_the_curves() -> void:
	var base := _stage()
	var hard := base.with_difficulty(_danger(4))
	assert_almost_eq(hard.hp_multiplier_at(10), base.hp_multiplier_at(10) * 1.3, 0.001)
	assert_almost_eq(hard.damage_multiplier_at(10), base.damage_multiplier_at(10) * 1.3, 0.001)
	assert_almost_eq(hard.spawn_rate_at(10), base.spawn_rate_at(10) * 1.15, 0.001)
	assert_gt(hard.steady_elite_chance, 0.0)
	var neutral := base.with_difficulty(_danger(0))
	assert_almost_eq(neutral.hp_multiplier_at(15), base.hp_multiplier_at(15), 0.001)


func test_danger_5_doubles_the_final_boss() -> void:
	var stage := _stage().with_difficulty(_danger(5))
	var count := 0
	for event in stage.events_for(stage.wave_count):
		count += event.count
	assert_eq(count, 2)


func test_endless_curves_keep_growing() -> void:
	var stage := _stage().copy()
	var last := stage.wave_count
	assert_almost_eq(stage.hp_multiplier_at(last + 5), stage.hp_multiplier_at(last), 0.001, "flat without endless")
	stage.endless = true
	assert_almost_eq(stage.hp_multiplier_at(last + 1), stage.hp_multiplier_at(last) * (1.0 + stage.endless_hp_growth), 0.001)
	assert_gt(stage.spawn_rate_at(last + 10), stage.spawn_rate_at(last))
	assert_eq(stage.duration_at(last + 1), stage.duration_last, "normal length after the final wave")
	assert_eq(stage.duration_at(last), stage.final_wave_duration)
	assert_false(stage.events_for(last + 10).is_empty(), "boss every 10 endless waves")
	assert_true(stage.events_for(last + 3).is_empty())


func test_wave_director_does_not_win_in_endless() -> void:
	var stage := _stage().copy()
	stage.endless = true
	var waves := WaveDirector.new()
	waves.setup(stage)
	add_child_autofree(waves)
	watch_signals(waves)
	waves.start_wave(stage.wave_count)
	assert_false(waves.is_last_wave())
	waves.finish_wave()
	waves._physics_process(0.016)
	assert_signal_emitted(waves, "wave_ended")
	assert_signal_not_emitted(waves, "run_won")


func test_difficulty_unlocks_per_character() -> void:
	var profile := Profile.new()
	assert_eq(profile.max_difficulty(&"drifter"), 0)
	var result := RunResult.new()
	result.character_id = &"drifter"
	result.won = true
	result.difficulty = 0
	SaveService.record_run(result)
	assert_eq(SaveService.profile.max_difficulty(&"drifter"), 1)
	assert_eq(SaveService.profile.max_difficulty(&"ronin"), 0, "per character")
	var back := Profile.from_dict(SaveService.profile.to_dict())
	assert_eq(back.max_difficulty(&"drifter"), 1)


func test_endless_record_is_kept_per_character() -> void:
	SaveService.record_endless(&"drifter", 27)
	SaveService.record_endless(&"drifter", 24)
	assert_eq(SaveService.profile.best_endless_wave_by_character.get(&"drifter", 0), 27)
	assert_eq(SaveService.profile.runs_played, 0, "not a new run")


func test_run_applies_the_chosen_difficulty() -> void:
	var setup := RunSetup.new()
	setup.character = ContentDB.get_def(&"characters", &"drifter")
	setup.difficulty = _danger(4)
	var run: Run = RUN.instantiate()
	run.setup = setup
	add_child_autofree(run)
	assert_almost_eq(run.stage.hp_multiplier_at(10), _stage().hp_multiplier_at(10) * 1.3, 0.001)
	assert_ne(run.stage, _stage(), "the shared stage is never modified")


func test_victory_offers_endless_and_continuing_resumes_the_run() -> void:
	var run: Run = RUN.instantiate()
	run.seed_override = 4
	add_child_autofree(run)
	run.waves.start_wave(run.stage.wave_count)
	run.waves.finish_wave()
	run.waves._physics_process(0.016)
	assert_true(run.game_over_screen.is_victory)
	assert_true(run.game_over_screen._endless.visible)
	run.game_over_screen._endless.pressed.emit()
	assert_false(run.game_over_screen.visible)
	assert_true(run.stage.endless)
	assert_false(run.state.is_over)


func test_character_select_offers_unlocked_dangers_only() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	screen._character_buttons[&"drifter"].pressed.emit()
	(screen._weapons.get_child(0) as Button).pressed.emit()
	assert_true(screen._dangers.visible)
	assert_false((screen._dangers.get_child(0) as Button).disabled)
	assert_true((screen._dangers.get_child(1) as Button).disabled, "Danger 1 needs a win at Danger 0")
	watch_signals(screen)
	(screen._dangers.get_child(0) as Button).pressed.emit()
	var setup: RunSetup = get_signal_parameters(screen, "started")[0]
	assert_eq(setup.difficulty.level, 0)
