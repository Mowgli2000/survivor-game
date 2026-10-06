extends GutTest
## Regression: Danger levels are unlocked per character, even after switching
## characters in the selection screen (bug reported by the dev).


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
	var enabled: Array[bool] = []
	for child in screen._dangers.get_children():
		if not child.is_queued_for_deletion():
			enabled.append(not (child as Button).disabled)
	return enabled


func test_switching_character_keeps_its_own_dangers() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	var drifter := _dangers_for(screen, &"drifter")
	assert_true(drifter[1], "Drifter: Danger 1 unlocked")
	screen._go_back()
	screen._go_back()
	var ronin := _dangers_for(screen, &"ronin")
	assert_false(ronin[1], "Ronin: Danger 1 still locked")


func test_a_drifter_run_does_not_unlock_dangers_for_others() -> void:
	var result := RunResult.new()
	result.character_id = &"drifter"
	result.won = true
	result.difficulty = 1
	SaveService.record_run(result)
	assert_eq(SaveService.profile.max_difficulty(&"drifter"), 2)
	assert_eq(SaveService.profile.max_difficulty(&"ronin"), 0)
	assert_eq(SaveService.profile.max_difficulty(&"gunslinger"), 0)


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
	assert_eq(SaveService.profile.max_difficulty(&"ronin"), 1)
	assert_eq(SaveService.profile.max_difficulty(&"gunslinger"), 0)


func test_picking_another_character_directly_resets_weapon_and_dangers() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	_dangers_for(screen, &"drifter")
	assert_true(screen._dangers.visible)
	# No "back": the dev clicks another character card while the Dangers row is shown.
	screen._character_buttons[&"ronin"].pressed.emit()
	assert_false(screen._dangers.visible, "the Drifter's dangers must not stay on screen")
	var ronin := _dangers_for(screen, &"ronin")
	assert_false(ronin[1], "Ronin: Danger 1 still locked")
	watch_signals(screen)
	(screen._dangers.get_child(0) as Button).pressed.emit()
	screen._launch.pressed.emit()
	var setup: RunSetup = get_signal_parameters(screen, "started")[0]
	assert_eq(setup.character.id, &"ronin")
	assert_true(setup.character.starting_weapons.has(setup.weapon), "a Ronin weapon, not the Drifter's")
