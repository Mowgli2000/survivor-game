extends GutTest
## Settings screen: controls mirror and write the Settings autoload.


func after_each() -> void:
	SafeFile.remove(Settings.TEST_PATH)
	Settings.load_settings()
	TranslationServer.set_locale("en")


func test_controls_show_current_values() -> void:
	Settings.set_value(&"screen_shake", false)
	Settings.set_value(&"music_volume", 0.4)
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.open()
	assert_false(screen._checks[&"screen_shake"].button_pressed)
	assert_almost_eq(screen._sliders[&"music_volume"].value, 0.4, 0.001)


func test_toggling_writes_the_setting() -> void:
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.open()
	screen._checks[&"damage_numbers"].button_pressed = false
	assert_false(Settings.data.damage_numbers)
	screen._language.select(2)
	screen._language.item_selected.emit(2)
	assert_eq(Settings.data.locale, "fr")


func test_back_closes() -> void:
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.open()
	watch_signals(screen)
	screen._back.pressed.emit()
	assert_false(screen.visible)
	assert_signal_emitted(screen, "closed")
