extends GutTest
## Solo class pick: validating a class on the gamepad leads to the look step, even after a click.


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func after_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func _open() -> CharacterSelect:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	return screen


func _click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event


func _pad_press() -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	return event


func test_gamepad_validate_goes_to_the_look_step() -> void:
	var screen := _open()
	var character: CharacterData = ContentDB.get_def(&"characters", &"drifter")
	screen._input(_pad_press())
	screen._choose_character(character)
	assert_eq(screen._step, CharacterSelect.Step.LOOK)


func test_gamepad_after_a_mouse_click_still_goes_to_the_look_step() -> void:
	var screen := _open()
	var character: CharacterData = ContentDB.get_def(&"characters", &"drifter")
	screen._input(_click())
	screen._input(_pad_press())
	screen._choose_character(character)
	assert_eq(screen._step, CharacterSelect.Step.LOOK, "the click must not make the gamepad skip the looks")


func test_mouse_click_still_goes_straight_to_the_weapons() -> void:
	var screen := _open()
	var character: CharacterData = ContentDB.get_def(&"characters", &"drifter")
	screen._input(_click())
	screen._choose_character(character)
	assert_eq(screen._step, CharacterSelect.Step.WEAPON)
