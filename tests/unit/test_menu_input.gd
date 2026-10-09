extends GutTest
## L1 / R1 in the menus (dev, 2026-10-09): they act as left / right wherever ui_left / ui_right do.


func _has_button(action: StringName, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return true
	return false


func test_bumpers_move_left_and_right_in_menus() -> void:
	assert_true(_has_button(&"ui_left", JOY_BUTTON_LEFT_SHOULDER), "L1 = left")
	assert_true(_has_button(&"ui_right", JOY_BUTTON_RIGHT_SHOULDER), "R1 = right")


func test_the_pad_and_stick_still_navigate() -> void:
	assert_true(_has_button(&"ui_left", JOY_BUTTON_DPAD_LEFT))
	assert_true(_has_button(&"ui_right", JOY_BUTTON_DPAD_RIGHT))
	var stick := false
	for event in InputMap.action_get_events(&"ui_left"):
		stick = stick or event is InputEventJoypadMotion
	assert_true(stick, "the left stick still goes left")


func test_installing_twice_adds_nothing() -> void:
	var before := InputMap.action_get_events(&"ui_left").size()
	MenuInput.install()
	MenuInput.install()
	assert_eq(InputMap.action_get_events(&"ui_left").size(), before)


func test_bumpers_do_not_move_the_hunter() -> void:
	for action in PlayerInput.MOVE_ACTIONS:
		assert_false(_has_button(action, JOY_BUTTON_LEFT_SHOULDER) or _has_button(action, JOY_BUTTON_RIGHT_SHOULDER))


func test_y_no_longer_turns_the_looks() -> void:
	assert_false(_has_button(&"switch_variant", JOY_BUTTON_Y), "Y keeps its other uses (reroll)")
	assert_true(_has_button(&"reroll", JOY_BUTTON_Y))


func test_a_bumper_press_is_a_left_press_for_the_menus() -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_LEFT_SHOULDER
	event.pressed = true
	assert_true(event.is_action_pressed("ui_left"))
	assert_eq(CoopCharacterSelect.action_of(event), &"ui_left")
