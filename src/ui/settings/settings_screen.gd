class_name SettingsScreen
extends Control
## Settings screen shared by the main menu and the pause menu (ADR 0013).
## Every control writes through Settings.set_value(); the screen keeps no state.
## Back button, `cancel` or `pause` close it.

signal closed

const VOLUMES: Array[StringName] = [&"master_volume", &"music_volume", &"sfx_volume"]
const DISPLAY: Array[StringName] = [&"fullscreen", &"vsync"]
const GAME: Array[StringName] = [&"screen_shake", &"damage_numbers", &"reduce_motion",
	&"show_hints", &"player_hp_bar"]
## Same order as SettingsData.LOCALES.
const LANGUAGE_KEYS: Array[String] = ["LANG_SYSTEM", "LANG_EN", "LANG_FR"]

var _sliders: Dictionary[StringName, HSlider] = {}
var _slider_values: Dictionary[StringName, Label] = {}
var _checks: Dictionary[StringName, CheckButton] = {}
var _language: OptionButton
## Background of the character select screens (SelectBackdrops).
var _background: BackdropPicker
var _back: Button
var _panel: PanelContainer
var _grid: GridContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = UiTheme.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "UI_SETTINGS"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 72)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 40)
	_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(_grid)

	_section("SET_SECTION_AUDIO")
	for key in VOLUMES:
		_add_slider(key)
	_section("SET_SECTION_DISPLAY")
	for key in DISPLAY:
		_add_check(key)
	_section("SET_SECTION_GAME")
	for key in GAME:
		_add_check(key)
	_row_label("SET_LANGUAGE")
	_language = OptionButton.new()
	for text in LANGUAGE_KEYS:
		_language.add_item(text)
	_language.item_selected.connect(func(index: int) -> void:
		Settings.set_value(&"locale", SettingsData.LOCALES[index]))
	_grid.add_child(_language)
	_row_label("SET_SELECT_BACKGROUND")
	_background = BackdropPicker.new()
	_grid.add_child(_background)

	_back = Button.new()
	_back.text = "UI_BACK"
	_back.custom_minimum_size = Vector2(260, 64)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	box.add_child(_back)
	add_child(ButtonHints.create([[&"A", "UI_HINT_ADJUST"], [&"B", "UI_HINT_BACK"]]))


func open() -> void:
	for key in _sliders:
		_sliders[key].set_value_no_signal(Settings.data.get(key))
		_update_slider_label(key)
	for key in _checks:
		_checks[key].set_pressed_no_signal(Settings.data.get(key))
	_language.select(maxi(SettingsData.LOCALES.find(Settings.data.locale), 0))
	_background.refresh()
	visible = true
	UiFx.pop_in(_panel)
	_sliders[VOLUMES[0]].grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _section(key: String) -> void:
	var label := Label.new()
	label.text = key
	label.theme_type_variation = &"SmallLabel"
	label.add_theme_color_override("font_color", UiTheme.VIOLET)
	label.add_theme_font_size_override("font_size", 20)
	_grid.add_child(label)
	_grid.add_child(Control.new())


func _row_label(key: String) -> void:
	var label := Label.new()
	label.text = key
	_grid.add_child(label)


func _add_slider(key: StringName) -> void:
	_row_label("SET_" + String(key).to_upper())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(320, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set_value(key, value)
		_update_slider_label(key))
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(70, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	_grid.add_child(row)
	_sliders[key] = slider
	_slider_values[key] = value_label


func _add_check(key: StringName) -> void:
	_row_label("SET_" + String(key).to_upper())
	var check := CheckButton.new()
	check.size_flags_horizontal = Control.SIZE_SHRINK_END
	check.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	_grid.add_child(check)
	_checks[key] = check


func _update_slider_label(key: StringName) -> void:
	_slider_values[key].text = "%d%%" % roundi(_sliders[key].value * 100.0)
