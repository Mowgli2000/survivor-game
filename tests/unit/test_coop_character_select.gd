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


## Hunter `player` picks class `id`, keeps its look and takes its first weapon.
func _pick(screen: CoopCharacterSelect, player: int, id: StringName) -> void:
	screen.cursor_to(player, id)
	screen.press(player, &"ui_accept")
	if screen.step_of(player) == CoopCharacterSelect.Step.LOOK:
		screen.press(player, &"ui_accept")
	screen.press(player, &"ui_accept")


func _joy(device: int, button: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button as JoyButton
	event.pressed = true
	return event


func test_seal_screen_opens_once_both_players_are_ready() -> void:
	var screen := _open()
	_pick(screen, 0, &"hero")
	assert_false(screen.seals().visible, "player 2 has not picked yet")
	_pick(screen, 1, &"hero")
	assert_true(screen.seals().visible)
	assert_false(screen._page.visible, "the pick hides behind it")


func test_run_starts_from_the_shared_seal_screen() -> void:
	var screen := _open()
	_pick(screen, 1, &"hero")
	_pick(screen, 0, &"hero")
	assert_null(_setup)
	screen.seals()._launch.pressed.emit()
	assert_not_null(_setup)
	assert_eq(_setup.character.id, &"hero")
	assert_eq(_setup.character_2.id, &"hero")
	assert_not_null(_setup.weapon)
	assert_not_null(_setup.weapon_2)
	assert_not_null(_setup.difficulty)


func test_back_from_the_seals_puts_both_players_on_their_weapons() -> void:
	var screen := _open()
	_pick(screen, 0, &"hero")
	_pick(screen, 1, &"hero")
	screen.seals()._go_back()
	assert_false(screen.seals().visible)
	assert_true(screen._page.visible)
	for i in 2:
		assert_eq(screen.step_of(i), CoopCharacterSelect.Step.WEAPON)
		assert_false(screen.seal_glow_of(i).lit)
	assert_null(_setup)


func test_a_ready_player_taking_back_the_weapon_waits_again() -> void:
	var screen := _open()
	_pick(screen, 0, &"hero")
	screen.press(0, &"cancel")
	assert_eq(screen.step_of(0), CoopCharacterSelect.Step.WEAPON)
	_pick(screen, 1, &"hero")
	assert_false(screen.seals().visible, "player 1 is not ready any more")


func test_the_seal_lights_up_once_its_hunter_is_ready() -> void:
	var screen := _open()
	screen.cursor_to(0, &"hero")
	screen.press(0, &"ui_accept")
	assert_false(screen.seal_glow_of(0).lit, "the class is chosen, not the weapon")
	_pick(screen, 0, &"hero")
	assert_true(screen.seal_glow_of(0).lit)
	assert_false(screen.seal_glow_of(1).lit, "the other seal stays dim")


func test_each_hunter_moves_his_own_cursor() -> void:
	var screen := _open()
	screen.press(1, &"ui_right")
	screen.press(1, &"ui_right")
	assert_eq(screen.cursor_of(0), 0)
	assert_eq(screen.cursor_of(1), 2)
	screen.press(0, &"ui_left")
	assert_eq(screen.cursor_of(0), 0, "the cursor stops at the first head")


func test_a_locked_class_cannot_be_validated() -> void:
	var screen := _open()
	var locked := -1
	for index in screen._characters.size():
		if not SaveService.is_unlocked(&"characters", screen._characters[index]):
			locked = index
			break
	assert_gt(locked, -1, "the roster has a class to unlock")
	screen.cursor_to(0, screen._characters[locked].id)
	screen.press(0, &"ui_accept")
	assert_eq(screen.step_of(0), CoopCharacterSelect.Step.LIST)


func test_back_from_the_list_closes_the_screen() -> void:
	var screen := _open()
	var closed := [false]
	screen.closed.connect(func() -> void: closed[0] = true)
	screen.press(0, &"cancel")
	assert_true(closed[0])
	assert_false(screen.visible)


func test_devices_drive_their_own_hunter() -> void:
	var screen := _open()
	screen._inputs = [PlayerInput.coop(0, 0, true), PlayerInput.coop(1, 1, false)]
	var key := InputEventKey.new()
	key.physical_keycode = KEY_RIGHT
	key.pressed = true
	assert_eq(screen.owner_of(key), 0, "the keyboard is hunter 1's")
	assert_eq(screen.owner_of(_joy(0, JOY_BUTTON_DPAD_RIGHT)), 0)
	assert_eq(screen.owner_of(_joy(1, JOY_BUTTON_DPAD_RIGHT)), 1)
	screen._input(_joy(1, JOY_BUTTON_DPAD_RIGHT))
	assert_eq(screen.cursor_of(1), 1, "pad 1 moved hunter 2 only")
	assert_eq(screen.cursor_of(0), 0)


func test_left_stick_moves_one_step_per_push() -> void:
	var screen := _open()
	screen._inputs = [PlayerInput.coop(0, 0, true), PlayerInput.coop(1, 1, false)]
	for value in [0.2, 0.6, 0.9, 1.0]:
		var motion := InputEventJoypadMotion.new()
		motion.device = 1
		motion.axis = JOY_AXIS_LEFT_X
		motion.axis_value = value
		screen._input(motion)
	assert_eq(screen.cursor_of(1), 1, "one push, one step")


func test_the_look_is_chosen_with_left_and_right_before_the_weapon() -> void:
	var screen := _open()
	screen.cursor_to(0, &"hero")
	screen.press(0, &"ui_accept")
	assert_eq(screen.step_of(0), CoopCharacterSelect.Step.LOOK, "the class is locked: on to its look")
	screen.press(0, &"ui_right")
	assert_eq(screen.chosen_variant(0), 1, "right turns the hero")
	screen.press(0, &"ui_left")
	assert_eq(screen.chosen_variant(0), 0, "left turns him back")
	screen.press(0, &"ui_accept")
	assert_eq(screen.step_of(0), CoopCharacterSelect.Step.WEAPON, "the look is validated: the weapons")
	screen.press(0, &"cancel")
	assert_eq(screen.step_of(0), CoopCharacterSelect.Step.LOOK, "back from the weapons: the look")
	screen.press(0, &"cancel")
	assert_eq(screen.step_of(0), CoopCharacterSelect.Step.LIST, "back from the look: the bar")


func test_switch_variant_turns_the_look_of_the_class_under_the_cursor() -> void:
	var screen := _open()
	var turning: CharacterData = null
	for character in screen._characters:
		if SaveService.is_unlocked(&"characters", character) and character.look_count() > 1:
			turning = character
			break
	assert_not_null(turning, "a class with two looks is unlocked")
	screen.cursor_to(0, turning.id)
	screen.press(0, &"switch_variant")
	assert_eq(screen.chosen_variant(0), 1)
	assert_eq(screen.chosen_variant(1), 0, "the other hunter keeps his look")


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


func test_head_square_is_found_on_the_figure_of_each_card() -> void:
	for character: CharacterData in ContentDB.get_all(&"characters"):
		for look in 2:
			var art := character.card_art_for(look)
			if art == null:
				continue
			var region := CharacterSelect.head_region(art)
			assert_gt(region.size.x, 0.0, "%s look %d" % [character.id, look])
			assert_true(Rect2(Vector2.ZERO, art.get_size()).encloses(region), "%s look %d inside its card" % [character.id, look])


func test_platform_follows_the_width_of_the_lower_body() -> void:
	var berserker := ContentDB.get_def(&"characters", &"berserker") as CharacterData
	var art := berserker.card_art_for(1)
	var share := CharacterSelect.platform_per_hero(art, null)
	var expected := clampf(CharacterSelect.feet_band_share(art) * CharacterSelect.PLATFORM_MARGIN,
			CharacterSelect.PLATFORM_PER_HERO_MIN, CharacterSelect.PLATFORM_PER_HERO_MAX)
	assert_almost_eq(share, expected, 0.001)
	var wider := CharacterSelect.platform_per_hero(art, berserker.card_art_for(0))
	assert_gte(wider, share, "the platform fits the broader of the two looks")


func test_platform_shares_of_every_look_stay_in_range() -> void:
	for character: CharacterData in ContentDB.get_all(&"characters"):
		for look in 2:
			var art := character.card_art_for(look)
			if art == null:
				continue
			var share := CharacterSelect.platform_per_hero(art, null)
			assert_between(share, CharacterSelect.PLATFORM_PER_HERO_MIN, CharacterSelect.PLATFORM_PER_HERO_MAX,
					"%s look %d" % [character.id, look])


func test_seal_glow_rises_and_falls() -> void:
	var glow := SealGlow.new(&"amber")
	add_child_autofree(glow)
	glow.place(Vector2(500.0, 500.0), 400.0)
	assert_eq(glow.level(), 0.0)
	glow.set_lit(true)
	for i in 30:
		glow._process(0.05)
	assert_eq(glow.level(), 1.0, "fully lit after a second and a half")
	glow.set_lit(false)
	for i in 40:
		glow._process(0.05)
	assert_eq(glow.level(), 0.0, "dark again")


func test_seal_glow_is_centered_on_its_ellipse() -> void:
	var glow := SealGlow.new(&"cyan")
	add_child_autofree(glow)
	glow.place(Vector2(960.0, 700.0), 600.0)
	assert_almost_eq(glow.position.x + glow.size.x * 0.5, 960.0, 0.01)
	assert_almost_eq(glow.position.y + glow.size.y * SealGlow.CENTER_Y, 700.0, 0.01)


func test_solo_seal_lights_up_while_the_pointer_is_on_next() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	screen._character_buttons[&"hero"].pressed.emit()
	screen._turn.pressed.emit()
	(screen._weapons.get_child(0) as Button).pressed.emit()
	assert_true(screen._seal_glow.lit, "the focus lands on Next: the seal is lit")
	screen._next.focus_exited.emit()
	screen._next.mouse_exited.emit()
	assert_false(screen._seal_glow.lit, "dark when the pointer leaves")
	screen._next.mouse_entered.emit()
	assert_true(screen._seal_glow.lit, "the mouse over Next lights it too")
	screen._next.mouse_exited.emit()
	assert_false(screen._seal_glow.lit)


func test_portal_lightning_stays_silent_under_a_hidden_screen() -> void:
	# Regression (dev, 2026-10-09): the bolts and their sounds went on after the seal screen
	# was closed, because the effect only looked at its own visibility.
	var screen := Control.new()
	add_child_autofree(screen)
	var fx := PortalFx.new()
	screen.add_child(fx)
	fx.place(Vector2(300.0, 300.0), Vector2(100.0, 200.0))
	fx.intensity = 1.0
	screen.visible = false
	for i in 20:
		fx._process(0.1)
	assert_eq(fx.bolt_count(), 0, "no bolt is spawned while the screen is hidden")
	screen.visible = true
	for i in 20:
		fx._process(0.1)
	assert_gt(fx.bolt_count(), 0, "bolts come back with the screen")


func test_seal_numeral_mask_covers_the_whole_numeral() -> void:
	# Regression (dev, 2026-10-09): the serif bar under the I and the VI was not tinted, the
	# mask of the numeral was flattened too much.
	var code := (load("res://src/ui/character_select/seal_numeral.gdshader") as Shader).code
	assert_true(code.contains("vec2(0.8, 0.8)"), "the numeral disc is no longer flattened")
