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
## Tabs, in order: the key is also the tab's title.
const TABS: Array[String] = ["SET_SECTION_AUDIO", "SET_SECTION_DISPLAY", "SET_SECTION_GAME",
	"SET_SECTION_ACCESSIBILITY"]
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
var _grid: GridContainer  # the page being filled while the screen is built
var _pages: Array[GridContainer] = []
var _tab_buttons: Array[Button] = []
var _stack: Control
var _tab_group := ButtonGroup.new()


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
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 10)
	box.add_child(tab_row)
	_stack = Control.new()
	box.add_child(_stack)

	_add_page(tab_row, 0)
	for key in VOLUMES:
		_add_slider(key)
	_add_page(tab_row, 1)
	for key in DISPLAY:
		_add_check(key)
	_fps_cap = _add_option(&"fps_cap", _fps_labels(), SettingsData.FPS_CAPS)
	_resolution = _add_option(&"resolution", _resolution_labels(), range(SettingsData.RESOLUTIONS.size() + 1))
	_add_page(tab_row, 2)
	_add_slider(&"camera_zoom", SettingsData.ZOOM_MIN, SettingsData.ZOOM_MAX)
	for key in GAME:
		_add_check(key)
	_row_label("SET_LANGUAGE")
	_language = OptionButton.new()
	for text in LANGUAGE_KEYS:
		_language.add_item(text)
	_language.item_selected.connect(func(index: int) -> void:
		Settings.set_value(&"locale", SettingsData.LOCALES[index]))
	_grid.add_child(_language)
	_add_page(tab_row, 3)
	_text_size = _add_option(&"text_size", ["SET_TEXT_SIZE_NORMAL", "SET_TEXT_SIZE_LARGE", "SET_TEXT_SIZE_XLARGE"], range(3))
	_colorblind = _add_option(&"colorblind", ["SET_COLORBLIND_OFF", "SET_COLORBLIND_PROTAN", "SET_COLORBLIND_DEUTAN",
		"SET_COLORBLIND_TRITAN"], range(SettingsData.COLORBLIND_MODES))
	_add_check(&"reduce_flashes")

	_back = Button.new()
	_back.text = "UI_BACK"
	_back.custom_minimum_size = Vector2(260, 64)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	box.add_child(_back)
	add_child(ButtonHints.create([[&"A", "UI_HINT_ADJUST"], [&"B", "UI_HINT_BACK"]]))


## The tab buttons sit side by side; down enters the page of the tab, up and down then walk its rows and the Back
## button in order.
func _link_focus() -> void:
	for tab in _pages.size():
		var chain: Array[Control] = [_tab_buttons[tab]]
		for node in _pages[tab].get_children():
			if node is Control and (node as Control).focus_mode == Control.FOCUS_ALL:
				chain.append(node)
			elif node is HBoxContainer:
				chain.append(node.get_child(0))  # the slider of a slider row
		chain.append(_back)
		for i in range(1, chain.size()):
			chain[i].focus_neighbor_top = chain[i].get_path_to(chain[i - 1])
			if i + 1 < chain.size():
				chain[i].focus_neighbor_bottom = chain[i].get_path_to(chain[i + 1])
		_tab_buttons[tab].focus_neighbor_bottom = _tab_buttons[tab].get_path_to(chain[1])
	_back.focus_neighbor_top = _back.get_path_to(_tab_buttons[0])


## Shows the page of tab `index`; Back goes up into that page.
func _show_tab(index: int) -> void:
	for i in _pages.size():
		_pages[i].visible = i == index
	var rows := _pages[index].get_children().filter(func(n: Node) -> bool: return n is Control and (n as Control).focus_mode == Control.FOCUS_ALL or n is HBoxContainer)
	if not rows.is_empty():
		var last: Control = rows[-1] if rows[-1].focus_mode == Control.FOCUS_ALL else rows[-1].get_child(0)
		_back.focus_neighbor_top = _back.get_path_to(last)
		last.focus_neighbor_bottom = last.get_path_to(_back)


func open() -> void:
	if _tab_buttons[0].focus_neighbor_bottom.is_empty():
		_link_focus()
	var tallest := 0.0
	for page in _pages:
		tallest = maxf(tallest, page.get_combined_minimum_size().y)
	_stack.custom_minimum_size = Vector2(0, tallest)  # the panel keeps one height from tab to tab
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
	_tab_buttons[0].button_pressed = true
	_show_tab(0)
	_tab_buttons[0].grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


## A tab and its page of rows; the rows added next go to this page.
func _add_page(tab_row: HBoxContainer, index: int) -> void:
	var button := Button.new()
	button.text = TABS[index]
	button.toggle_mode = true
	button.button_group = _tab_group
	button.toggled.connect(func(on: bool) -> void:
		if on:
			_show_tab(index))
	button.focus_entered.connect(func() -> void: button.button_pressed = true)  # on a pad, moving onto a tab opens it
	tab_row.add_child(button)
	_tab_buttons.append(button)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 40)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_grid.visible = index == 0
	_stack.add_child(_grid)
	_pages.append(_grid)


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
