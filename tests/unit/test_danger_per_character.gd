extends GutTest
## Danger levels (seals) unlock globally: a win with any hunter opens the next seal
## for every hunter (dev's decision 2026-10-08, replaces the per-character rule).


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()
	SaveService.profile.unlock(&"characters", &"ronin")
	SaveService.profile.best_difficulty_by_character[&"drifter"] = 0  # won Danger 0 with the Drifter


func after_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func _dangers_for(screen: CharacterSelect, character: StringName) -> Array[bool]:
	screen._character_buttons[character].pressed.emit()
	(screen._weapons.get_child(0) as Button).pressed.emit()
	screen._next.pressed.emit()
	var enabled: Array[bool] = []
	for button in screen._seals.seal_buttons():
		enabled.append(not button.get_meta(&"locked"))
	return enabled


func test_another_hunter_gets_the_seal_a_win_opened() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	var drifter := _dangers_for(screen, &"drifter")
	assert_true(drifter[1], "Danger 1 open after a Drifter win")
	screen._seals._go_back()
	screen._go_back()
	screen._go_back()
	var ronin := _dangers_for(screen, &"ronin")
	assert_true(ronin[1], "Danger 1 open for the Ronin too")
	assert_false(ronin[2], "Danger 2 still locked")


func test_a_win_with_any_hunter_opens_the_next_seal_for_all() -> void:
	var result := RunResult.new()
	result.character_id = &"drifter"
	result.won = true
	result.difficulty = 1
	SaveService.record_run(result)
	assert_eq(SaveService.profile.max_difficulty(), 2)
	assert_eq(SaveService.profile.best_difficulty_by_character.get(&"ronin", -1), -1, "record stays per character")


func test_a_run_started_from_the_menu_records_its_own_character() -> void:
	var setup := RunSetup.new()
	setup.character = ContentDB.get_def(&"characters", &"ronin")
	setup.weapon = ContentDB.get_def(&"weapons", &"katana")
	setup.difficulty = ContentDB.get_def(&"difficulties", &"danger_0")
	var run: Run = preload("res://src/run/run.tscn").instantiate()
	run.setup = setup
	add_child_autofree(run)
	run._record_run(true)
	get_tree().paused = false
	assert_eq(SaveService.profile.best_difficulty_by_character.get(&"ronin", -1), 0)
	assert_eq(SaveService.profile.max_difficulty(), 1)


func test_picking_another_character_directly_resets_weapon() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	_dangers_for(screen, &"drifter")
	assert_true(screen._seals.visible)
	screen._seals._go_back()
	screen._character_buttons[&"ronin"].pressed.emit()
	assert_false(screen._seals.visible, "the Drifter's seals must not stay on screen")
	_dangers_for(screen, &"ronin")
	watch_signals(screen)
	screen._seals._launch.pressed.emit()
	var setup: RunSetup = get_signal_parameters(screen, "started")[0]
	assert_eq(setup.character.id, &"ronin")
	assert_true(setup.character.starting_weapons.has(setup.weapon), "a Ronin weapon, not the Drifter's")
