extends GutTest
## Pause menu: opens only during a wave, pauses the tree, confirms before abandoning.

const RUN := preload("res://src/run/run.tscn")

var _run: Run


func before_each() -> void:
	_run = RUN.instantiate()
	_run.seed_override = 1
	add_child_autofree(_run)


func after_each() -> void:
	get_tree().paused = false
	SafeFile.remove(Settings.TEST_PATH)
	Settings.load_settings()


func test_pause_opens_during_a_wave_and_resume_unpauses() -> void:
	assert_true(_run.can_pause())
	_run.open_pause()
	assert_true(get_tree().paused)
	assert_true(_run.pause_menu.visible)
	_run.pause_menu._resume.pressed.emit()
	assert_false(get_tree().paused)
	assert_false(_run.pause_menu.visible)


func test_no_pause_when_another_screen_paused_the_game() -> void:
	get_tree().paused = true
	assert_false(_run.can_pause())


func test_abandon_asks_for_confirmation() -> void:
	_run.open_pause()
	var menu := _run.pause_menu
	watch_signals(menu)
	menu._restart.pressed.emit()
	assert_true(menu._confirm.visible)
	assert_false(menu._buttons.visible)
	menu._no.pressed.emit()
	assert_true(menu._buttons.visible)
	assert_signal_not_emitted(menu, "restart_requested")
	menu._restart.pressed.emit()
	# Disconnect the run so confirming does not reload the test scene.
	menu.restart_requested.disconnect(_run._on_retry_requested)
	menu._yes.pressed.emit()
	assert_signal_emitted(menu, "restart_requested")


func test_escape_in_settings_goes_back_not_resume() -> void:
	_run.open_pause()
	var menu := _run.pause_menu
	menu._settings_button.pressed.emit()
	var event := InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	menu._settings._unhandled_input(event)
	assert_false(menu._settings.visible)
	assert_true(menu.visible, "still paused")
	assert_true(get_tree().paused)


func test_settings_reach_damage_numbers_and_camera() -> void:
	Settings.set_value(&"damage_numbers", false)
	Settings.set_value(&"screen_shake", false)
	assert_false(_run.damage_numbers.enabled)
	assert_false(_run.camera.shake_enabled)
	SafeFile.remove(Settings.TEST_PATH)
	Settings.load_settings()
	assert_true(_run.damage_numbers.enabled)


func test_game_over_has_a_main_menu_button() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	watch_signals(screen)
	screen._main_menu.pressed.emit()
	assert_signal_emitted(screen, "main_menu_requested")
