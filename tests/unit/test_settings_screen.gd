extends GutTest
## Settings screen: controls mirror and write the Settings autoload.


func after_each() -> void:
	UiTheme.set_text_scale(1.0)
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


func test_the_graphics_options_write_the_settings() -> void:
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.open()
	screen._fps_cap.item_selected.emit(2)  # 60 fps
	assert_eq(Settings.data.fps_cap, 60)
	screen._resolution.item_selected.emit(3)  # 1920 x 1080
	assert_eq(Settings.data.resolution, 3)
	screen._checks[&"light_mode"].button_pressed = true
	assert_true(Settings.data.light_mode)


func test_the_accessibility_options_apply_at_once() -> void:
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.open()
	var normal := UiTheme.get_theme().default_font_size
	screen._text_size.item_selected.emit(2)
	assert_eq(UiTheme.get_theme().default_font_size, roundi(normal * 1.3), "the theme every screen holds is resized")
	assert_eq(UiTheme.scaled(20), 26)
	screen._colorblind.item_selected.emit(1)
	assert_eq(Settings.data.colorblind, 1)
	assert_true(Settings._color_filter._rect.visible, "the screen filter is on")
	screen._colorblind.item_selected.emit(0)
	assert_false(Settings._color_filter._rect.visible, "and off again")
	screen._checks[&"reduce_flashes"].button_pressed = true
	assert_true(Settings.data.reduce_flashes)


func test_the_controls_tab_captures_the_next_key_and_escape_gives_up() -> void:
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.open()
	screen._bind_buttons["pause:0"].pressed.emit()
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	screen._input(escape)
	assert_true(screen._capture.is_empty(), "Escape gives up")
	assert_true(Settings.data.bindings.is_empty(), "and changes nothing")
	screen._bind_buttons["pause:0"].pressed.emit()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_O
	key.pressed = true
	screen._input(key)
	assert_eq(int(InputBindings.resolved(Settings.data.bindings)[&"pause"][0]), int(KEY_O))
	assert_eq(screen._bind_buttons["pause:0"].text, InputBindings.key_text(KEY_O))
	InputBindings.apply({})
