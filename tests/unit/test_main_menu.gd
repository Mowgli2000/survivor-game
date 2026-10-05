extends GutTest
## Main menu: loads, Play focused, settings open and close.


func test_main_scene_is_the_main_menu() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), SceneRouter.MAIN_MENU)


func test_menu_builds_with_a_crowd_and_focus_on_play() -> void:
	var menu: MainMenu = load(SceneRouter.MAIN_MENU).instantiate()
	add_child_autofree(menu)
	await wait_process_frames(2)
	assert_true(menu._play.has_focus())
	assert_gt(menu._crowd.count(), 0)


func test_settings_open_and_close() -> void:
	var menu: MainMenu = load(SceneRouter.MAIN_MENU).instantiate()
	add_child_autofree(menu)
	menu._settings_button.pressed.emit()
	assert_true(menu._settings.visible)
	assert_false(menu._buttons.visible)
	menu._settings.close()
	assert_true(menu._buttons.visible)


## Godot's default ui_accept / ui_cancel have no gamepad button: menus could not
## be validated with A / Cross (bug found by the dev on the main menu).
func test_gamepad_buttons_press_and_cancel_menus() -> void:
	assert_true(_has_joy_button(&"ui_accept", JOY_BUTTON_A), "A / Cross presses buttons")
	assert_true(_has_joy_button(&"ui_cancel", JOY_BUTTON_B), "B / Circle goes back")


func _has_joy_button(action: StringName, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return true
	return false


func test_main_menu_shows_the_project_version() -> void:
	assert_eq(MainMenu.version_text(), "v" + str(ProjectSettings.get_setting("application/config/version")))
	assert_ne(MainMenu.version_text(), "v0")
