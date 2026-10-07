extends GutTest
## Split-screen coop pick: both players pick at once, player 1 then picks the seal.

var _setup: RunSetup


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()
	_setup = null


func after_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func _open() -> CoopCharacterSelect:
	var screen := CoopCharacterSelect.new()
	add_child_autofree(screen)
	screen.started.connect(func(setup: RunSetup) -> void: _setup = setup)
	screen.open()
	return screen


func _pick(half: CharacterSelect, id: StringName) -> void:
	half._choose_character(ContentDB.get_def(&"characters", id) as CharacterData)
	(half._weapons.get_child(0) as Button).pressed.emit()


func test_player_1_picks_the_seal_without_waiting() -> void:
	var screen := _open()
	_pick(screen.select_of(0), &"hero")
	assert_true(screen.select_of(0)._dangers.visible, "seals right after the weapon")
	assert_false(screen.select_of(1)._dangers.visible, "player 2 has no seals")


func test_run_starts_when_player_2_is_ready_after_player_1_pressed_play() -> void:
	var screen := _open()
	_pick(screen.select_of(0), &"hero")
	screen.select_of(0)._launch.pressed.emit()
	assert_null(_setup, "player 2 has not picked yet")
	_pick(screen.select_of(1), &"hero")
	assert_not_null(_setup, "starts without player 1 pressing again")
	assert_eq(_setup.character.id, &"hero")
	assert_eq(_setup.character_2.id, &"hero")
	assert_not_null(_setup.weapon_2)
	assert_not_null(_setup.difficulty)


func test_run_starts_when_player_1_presses_play_after_player_2() -> void:
	var screen := _open()
	_pick(screen.select_of(1), &"hero")
	_pick(screen.select_of(0), &"hero")
	assert_null(_setup)
	screen.select_of(0)._launch.pressed.emit()
	assert_not_null(_setup)


func test_player_1_taking_back_play_cancels_the_start() -> void:
	var screen := _open()
	_pick(screen.select_of(0), &"hero")
	screen.select_of(0)._launch.pressed.emit()
	screen.select_of(0)._go_back()
	assert_false(screen.select_of(0).is_ready)
	assert_true(screen.select_of(0)._launch.visible, "Play is back")
	_pick(screen.select_of(1), &"hero")
	assert_null(_setup)


func test_seal_is_lowered_to_what_player_2_unlocked() -> void:
	var levels: Array[DifficultyData] = []
	levels.assign(ContentDB.get_all(&"difficulties"))
	levels.sort_custom(func(a: DifficultyData, b: DifficultyData) -> bool: return a.level < b.level)
	var hero := ContentDB.get_def(&"characters", &"hero") as CharacterData
	var allowed := SaveService.profile.max_difficulty(hero.id)
	var too_high := levels[mini(allowed + 1, levels.size() - 1)]
	var shared := CoopCharacterSelect.shared_difficulty(too_high, hero)
	assert_lte(shared.level, allowed)


func test_gamepad_focus_on_a_head_shows_the_hero() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_DPAD_RIGHT
	event.pressed = true
	screen._input(event)
	var hero := screen._character_buttons[&"hero"]
	hero.grab_focus()
	assert_eq(screen._shown.id, &"hero", "shown without pressing A")


func test_keyboard_focus_does_not_show_the_hero() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	screen._input(InputEventKey.new())
	var first := screen._shown
	assert_not_null(first, "the first class is shown on arrival")
	screen._character_buttons[&"hero"].grab_focus()
	assert_eq(screen._shown, first, "keyboard: only a press shows another hero")


func test_gamepad_focus_on_a_head_shows_its_starting_weapons() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_DPAD_RIGHT
	event.pressed = true
	screen._input(event)
	screen._character_buttons[&"drifter"].grab_focus()
	var hero: Button = screen._character_buttons[&"hero"]
	hero.grab_focus()
	assert_true(screen._weapons.visible, "weapons shown on hover")
	assert_eq(screen.chosen_character().id, &"hero")
	assert_eq(get_viewport().gui_get_focus_owner(), hero, "the focus stays on the heads")


func test_new_flow_list_then_look_then_weapons() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	assert_eq(screen._step, CharacterSelect.Step.LIST)
	screen._character_buttons[&"hero"].pressed.emit()
	assert_eq(screen._step, CharacterSelect.Step.LOOK, "a row press goes to the turntable")
	var look := screen.chosen_variant()
	screen._turn_look(1)
	assert_ne(screen.chosen_variant(), look, "the turntable turns")
	screen._turn.pressed.emit()
	assert_eq(screen._step, CharacterSelect.Step.WEAPON, "A on the turntable goes to the weapons")
	screen._go_back()
	assert_eq(screen._step, CharacterSelect.Step.LOOK, "B: back to the look")
	screen._go_back()
	assert_eq(screen._step, CharacterSelect.Step.LIST, "B: back to the list")


func test_feet_anchor_is_inside_the_art() -> void:
	var hero := ContentDB.get_def(&"characters", &"hero") as CharacterData
	var anchor := CharacterSelect.feet_anchor(hero.card_art_for(0))
	assert_between(anchor.x, 0.2, 0.8, "feet near the middle")
	assert_gt(anchor.y, 0.8, "feet at the bottom")
