class_name CreditsScreen
extends Control
## Credits screen, opened from the main menu. A framed panel with a scrolling list of sections (heading + lines).
## It drifts slowly by itself; the mouse wheel, up/down keys and the pad stick scroll it by hand (and stop the drift).
## Reads only: the data below and the translated headings.

signal closed

## Scroll speeds, in pixels per second.
const DRIFT_SPEED := 36.0
const MANUAL_SPEED := 420.0
const VIEW_SIZE := Vector2(1080.0, 600.0)
## Name shown for the developer.
const DEVELOPER := "Raphaël Debongnie"
## Sections: [heading key, lines]. A line that is a key of strings.csv is translated; the rest are names and
## licences, shown as they are. Source of truth for the licences: assets/CREDITS.md.
const SECTIONS: Array = [
	["CREDITS_DEVELOPMENT", ["CREDITS_GAME_BY", DEVELOPER]],
	["CREDITS_MUSIC", [
		"Dark Shrine Loop — qubodup (CC0)",
		"Battle Theme A — cynicmusic.com / pixelsphere.org (CC0)",
		"Battle RPG Theme — CleytonRX (CC0)",
		"opengameart.org",
	]],
	["CREDITS_SOUNDS", [
		"CREDITS_SOUNDS_ELEVENLABS",
		"Kenney — kenney.nl (CC0)",
		"OpenGameArt — opengameart.org (CC0)",
	]],
	["CREDITS_FONTS", [
		"Fredoka — Milena Brandão, Hafontia",
		"Nunito — Vernon Adams, Cyreal, Jacques Le Bailly",
		"Bangers — Vernon Adams",
		"Cinzel — Natanael Gama",
		"CREDITS_FONTS_LICENSE",
	]],
	["CREDITS_AI", ["CREDITS_AI_TEXT"]],
	["CREDITS_TOOLS", [
		"Godot Engine — godotengine.org (MIT)",
		"GUT — Gut Unit Testing (MIT)",
	]],
	["CREDITS_THANKS", ["CREDITS_THANKS_TEXT"]],
]

var _panel: PanelContainer
var _scroll: ScrollContainer
var _back: Button
var _drifting: bool = true


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
	title.text = "UI_CREDITS"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", UiTheme.scaled(72))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = VIEW_SIZE
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.gui_input.connect(_on_scroll_input)
	box.add_child(_scroll)
	_scroll.add_child(_build_list())
	_back = Button.new()
	_back.text = "UI_BACK"
	_back.custom_minimum_size = Vector2(260, 64)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	box.add_child(_back)
	add_child(ButtonHints.create([[&"B", "UI_HINT_BACK"]]))


## The sections one under the other: a coloured heading, then its lines, centred.
func _build_list() -> VBoxContainer:
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = VIEW_SIZE.x
	list.add_theme_constant_override("separation", 10)
	list.add_child(_gap(VIEW_SIZE.y * 0.3))
	for section: Array in SECTIONS:
		var heading := Label.new()
		heading.text = section[0]
		heading.theme_type_variation = &"SubtitleLabel"
		heading.add_theme_font_size_override("font_size", UiTheme.scaled(40))
		heading.add_theme_color_override("font_color", UiTheme.ACCENT)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(heading)
		for line: String in section[1]:
			var label := Label.new()
			label.text = line
			label.add_theme_font_size_override("font_size", UiTheme.scaled(28))
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size.x = VIEW_SIZE.x - 40.0
			list.add_child(label)
		list.add_child(_gap(36.0))
	list.add_child(_gap(VIEW_SIZE.y * 0.5))
	return list


func _gap(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	return gap


func open() -> void:
	visible = true
	_drifting = true
	_scroll.scroll_vertical = 0
	UiFx.pop_in(_panel)
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Drift while nothing is pressed; up/down (keys or stick) scroll by hand and stop the drift.
func _process(delta: float) -> void:
	if not visible:
		return
	var axis := Input.get_axis("ui_up", "ui_down")
	if absf(axis) > 0.1:
		_drifting = false
		_scroll.scroll_vertical += roundi(axis * MANUAL_SPEED * delta)
	elif _drifting and not Settings.data.reduce_motion:
		_scroll.scroll_vertical += maxi(roundi(DRIFT_SPEED * delta), 1)


func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenDrag:
		_drifting = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()
