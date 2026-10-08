extends GutTest
## Split-screen coop pick: both players pick at once, then the shared seal screen.

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
	half._next.pressed.emit()


func test_seal_screen_opens_once_both_players_are_ready() -> void:
	var screen := _open()
	_pick(screen.select_of(0), &"hero")
	assert_false(screen.seals().visible, "player 2 has not picked yet")
	_pick(screen.select_of(1), &"hero")
	assert_true(screen.seals().visible)
	assert_false(screen.select_of(0).is_visible_in_tree(), "the halves hide behind it")


func test_run_starts_from_the_shared_seal_screen() -> void:
	var screen := _open()
	_pick(screen.select_of(1), &"hero")
	_pick(screen.select_of(0), &"hero")
	assert_null(_setup)
	screen.seals()._launch.pressed.emit()
	assert_not_null(_setup)
	assert_eq(_setup.character.id, &"hero")
	assert_eq(_setup.character_2.id, &"hero")
	assert_not_null(_setup.weapon_2)
	assert_not_null(_setup.difficulty)


func test_back_from_the_seals_puts_both_players_on_their_weapons() -> void:
	var screen := _open()
	_pick(screen.select_of(0), &"hero")
	_pick(screen.select_of(1), &"hero")
	screen.seals()._go_back()
	assert_false(screen.seals().visible)
	for i in 2:
		assert_false(screen.select_of(i).is_ready)
		assert_true(screen.select_of(i).is_visible_in_tree())
		assert_eq(screen.select_of(i)._step, CharacterSelect.Step.WEAPON)
	assert_null(_setup)


func test_a_ready_player_taking_back_the_weapon_waits_again() -> void:
	var screen := _open()
	_pick(screen.select_of(0), &"hero")
	screen.select_of(0)._go_back()
	assert_false(screen.select_of(0).is_ready)
	_pick(screen.select_of(1), &"hero")
	assert_false(screen.seals().visible, "player 1 is not ready any more")


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


func test_only_the_current_step_can_take_the_focus() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	assert_eq(screen._character_buttons[&"hero"].focus_mode, Control.FOCUS_ALL, "list: focusable")
	assert_eq(screen._turn.focus_mode, Control.FOCUS_NONE, "turntable: not yet")
	for weapon in screen._weapons.get_children():
		assert_eq((weapon as Control).focus_mode, Control.FOCUS_NONE, "weapons: not yet")
	screen._character_buttons[&"hero"].pressed.emit()
	assert_eq(screen._character_buttons[&"hero"].focus_mode, Control.FOCUS_NONE, "list left behind")
	assert_eq(screen._turn.focus_mode, Control.FOCUS_ALL)
	screen._turn.pressed.emit()
	assert_eq(screen._turn.focus_mode, Control.FOCUS_NONE)
	for weapon in screen._weapons.get_children():
		assert_eq((weapon as Control).focus_mode, Control.FOCUS_ALL, "weapons: now")


func test_every_class_rule_is_translated_and_shown() -> void:
	var screen := CharacterSelect.new(true)
	add_child_autofree(screen)
	screen.open(0)
	for character: CharacterData in ContentDB.get_all(&"characters"):
		assert_ne(character.description_key, "", "%s has a rule" % character.id)
		assert_ne(tr(character.description_key), character.description_key, "%s: rule translated" % character.id)
		screen._show_hero(character)
		assert_true(screen._hero_rule.is_visible_in_tree(), "%s: rule label visible in coop" % character.id)
		if SaveService.is_unlocked(&"characters", character):
			assert_eq(screen._hero_rule.text, character.description_key, "%s: rule shown" % character.id)
		else:
			assert_string_contains(screen._hero_rule.text, "Locked", "%s: unlock hint instead of the rule" % character.id)


func test_stats_show_numbers_and_the_difference_with_the_base() -> void:
	var berserker := ContentDB.get_def(&"characters", &"berserker") as CharacterData
	var deltas := CharacterSelect.stat_deltas(berserker)
	assert_eq(deltas[StatIds.MAX_HP][0], "(+30)")
	var values := CharacterSelect.stat_values(berserker)
	assert_eq(values[StatIds.MAX_HP], "130")
	var hero := ContentDB.get_def(&"characters", &"hero") as CharacterData
	assert_eq(CharacterSelect.stat_deltas(hero)[StatIds.MAX_HP][0], "(-15)")
	assert_eq(CharacterSelect.stat_deltas(hero)[StatIds.MOVE_SPEED][0], "(+30)")


func test_stat_bars_tell_the_classes_apart() -> void:
	var fills := []
	for character: CharacterData in ContentDB.get_all(&"characters"):
		fills.append(CharacterSelect.stat_preview(character)[StatIds.MAX_HP])
	assert_almost_eq(fills.max(), 1.0, 0.001, "the best class has a full bar")
	assert_almost_eq(fills.min(), 0.25, 0.001, "the weakest keeps a visible bar")


func test_validating_a_weapon_opens_the_seals_and_back_returns_to_the_weapons() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	screen._character_buttons[&"hero"].pressed.emit()
	screen._turn.pressed.emit()
	(screen._weapons.get_child(0) as Button).pressed.emit()
	assert_false(screen._seals.visible, "a weapon press only picks it")
	assert_true(screen._next.visible)
	screen._next.pressed.emit()
	assert_true(screen._seals.visible)
	screen._seals._go_back()
	assert_false(screen._seals.visible)
	assert_eq(screen._step, CharacterSelect.Step.WEAPON, "B: back to the weapons")
	assert_eq((screen._weapons.get_child(0) as Control).focus_mode, Control.FOCUS_ALL)
