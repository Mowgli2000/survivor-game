class_name SettingsScreen
extends Control
## Settings screen shared by the main menu and the pause menu (ADR 0013).
## Every control writes through Settings.set_value(); the screen keeps no state.
## Back button, `cancel` or `pause` close it.

signal closed

const VOLUMES: Array[StringName] = [&"master_volume", &"music_volume", &"sfx_volume", &"ambience_volume"]
const DISPLAY: Array[StringName] = [&"fullscreen", &"vsync", &"light_mode"]
const GAME: Array[StringName] = [&"screen_shake", &"damage_numbers", &"reduce_motion",
	&"show_hints", &"player_hp_bar"]
## Height of the scrolling list of settings, px.
const LIST_HEIGHT := 640.0
## Same order as SettingsData.LOCALES.
const LANGUAGE_KEYS: Array[String] = ["LANG_SYSTEM", "LANG_EN", "LANG_FR"]

var _sliders: Dictionary[StringName, HSlider] = {}
var _slider_values: Dictionary[StringName, Label] = {}
var _checks: Dictionary[StringName, CheckButton] = {}
var _language: OptionButton
var _fps_cap: OptionButton
var _resolution: OptionButton
var _text_size: OptionButton
var _colorblind: OptionButton
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
	title.add_theme_font_size_override("font_size", UiTheme.scaled(72))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	# The rows scroll: the list is longer than a 720p screen (focus scrolls it into view).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, LIST_HEIGHT)
	box.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 40)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	_section("SET_SECTION_AUDIO")
	for key in VOLUMES:
		_add_slider(key)
	_section("SET_SECTION_DISPLAY")
	for key in DISPLAY:
		_add_check(key)
	_fps_cap = _add_option(&"fps_cap", _fps_labels(), SettingsData.FPS_CAPS)
	_resolution = _add_option(&"resolution", _resolution_labels(), range(SettingsData.RESOLUTIONS.size() + 1))
	_section("SET_SECTION_GAME")
	_add_slider(&"camera_zoom", SettingsData.ZOOM_MIN, SettingsData.ZOOM_MAX)
	for key in GAME:
		_add_check(key)
	_section("SET_SECTION_ACCESSIBILITY")
	_text_size = _add_option(&"text_size", ["SET_TEXT_SIZE_NORMAL", "SET_TEXT_SIZE_LARGE", "SET_TEXT_SIZE_XLARGE"], range(3))
	_colorblind = _add_option(&"colorblind", ["SET_COLORBLIND_OFF", "SET_COLORBLIND_PROTAN", "SET_COLORBLIND_DEUTAN",
		"SET_COLORBLIND_TRITAN"], range(SettingsData.COLORBLIND_MODES))
	_add_check(&"reduce_flashes")
	_row_label("SET_LANGUAGE")
	_language = OptionButton.new()
	for text in LANGUAGE_KEYS:
		_language.add_item(text)
	_language.item_selected.connect(func(index: int) -> void:
		Settings.set_value(&"locale", SettingsData.LOCALES[index]))
	_grid.add_child(_language)

	_back = Button.new()
	_back.text = "UI_BACK"
	_back.custom_minimum_size = Vector2(260, 64)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	box.add_child(_back)
	add_child(ButtonHints.create([[&"A", "UI_HINT_ADJUST"], [&"B", "UI_HINT_BACK"]]))


## Up and down walk the rows in order, then the Back button (the list scrolls, so the position of a row says
## little about its neighbours).
func _link_focus() -> void:
	var chain: Array[Control] = []
	for node in _grid.get_children():
		if node is Control and (node as Control).focus_mode == Control.FOCUS_ALL:
			chain.append(node)
		elif node is HBoxContainer:
			chain.append(node.get_child(0))  # the slider of a slider row
	chain.append(_back)
	for i in chain.size():
		var above := chain[maxi(i - 1, 0)]
		var below := chain[mini(i + 1, chain.size() - 1)]
		chain[i].focus_neighbor_top = chain[i].get_path_to(above)
		chain[i].focus_neighbor_bottom = chain[i].get_path_to(below)


func open() -> void:
	if _grid.get_child_count() > 0 and _sliders[VOLUMES[0]].focus_neighbor_bottom.is_empty():
		_link_focus()
	for key in _sliders:
		_sliders[key].set_value_no_signal(Settings.data.get(key))
		_update_slider_label(key)
	for key in _checks:
		_checks[key].set_pressed_no_signal(Settings.data.get(key))
	_language.select(maxi(SettingsData.LOCALES.find(Settings.data.locale), 0))
	_fps_cap.select(maxi(SettingsData.FPS_CAPS.find(Settings.data.fps_cap), 0))
	_resolution.select(Settings.data.resolution)
	_text_size.select(Settings.data.text_size)
	_colorblind.select(Settings.data.colorblind)
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
	label.add_theme_font_size_override("font_size", UiTheme.scaled(20))
	_grid.add_child(label)
	_grid.add_child(Control.new())


func _row_label(key: String) -> void:
	var label := Label.new()
	label.text = key
	_grid.add_child(label)


func _add_slider(key: StringName, min_value: float = 0.0, max_value: float = 1.0) -> void:
	_row_label("SET_" + String(key).to_upper())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
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


## A drop-down row for an integer setting: item `i` writes `values[i]`.
func _add_option(key: StringName, labels: Array[String], values: Array) -> OptionButton:
	_row_label("SET_" + String(key).to_upper())
	var option := OptionButton.new()
	for text in labels:
		option.add_item(text)
	option.item_selected.connect(func(index: int) -> void:
		Settings.set_value(key, values[index]))
	_grid.add_child(option)
	return option


func _fps_labels() -> Array[String]:
	var labels: Array[String] = []
	for cap in SettingsData.FPS_CAPS:
		labels.append("SET_FPS_UNLIMITED" if cap == 0 else str(cap))
	return labels


func _resolution_labels() -> Array[String]:
	var labels: Array[String] = ["SET_RESOLUTION_AUTO"]
	for size in SettingsData.RESOLUTIONS:
		labels.append("%d × %d" % [size.x, size.y])
	return labels


func _update_slider_label(key: StringName) -> void:
	_slider_values[key].text = "%d%%" % roundi(_sliders[key].value * 100.0)
