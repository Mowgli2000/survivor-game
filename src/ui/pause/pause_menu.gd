class_name PauseMenu
extends CanvasLayer
## Pause menu (ADR 0013): Resume / Settings / Restart / Main menu / Quit, with a
## confirmation before abandoning the run and the stats panel on the side.
## Emits requests only; Run unpauses or asks SceneRouter.

signal resume_requested
signal restart_requested
signal main_menu_requested
signal quit_requested

var stats_panel: StatsPanel

var _panel: PanelContainer
var _buttons: VBoxContainer
var _confirm: VBoxContainer
var _resume: Button
var _settings_button: Button
var _restart: Button
var _main_menu: Button
var _quit: Button
var _yes: Button
var _no: Button
var _settings: SettingsScreen
## Signal emitted when the player confirms.
var _pending: Signal
## Button to refocus when the confirmation is cancelled.
var _pending_button: Button


func _init() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.get_theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = UiTheme.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 48)
	center.add_child(row)
	_panel = PanelContainer.new()
	_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "UI_PAUSED"
	title.theme_type_variation = &"TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 12)
	box.add_child(_buttons)
	_resume = _button(_buttons, "UI_RESUME", func() -> void: resume_requested.emit())
	_settings_button = _button(_buttons, "UI_SETTINGS", _open_settings)
	_restart = _button(_buttons, "UI_RESTART", func() -> void: _ask(restart_requested, _restart))
	_main_menu = _button(_buttons, "UI_MAIN_MENU", func() -> void: _ask(main_menu_requested, _main_menu))
	_quit = _button(_buttons, "UI_QUIT", func() -> void: _ask(quit_requested, _quit))

	_confirm = VBoxContainer.new()
	_confirm.add_theme_constant_override("separation", 12)
	_confirm.visible = false
	box.add_child(_confirm)
	var question := Label.new()
	question.text = "UI_CONFIRM_ABANDON"
	question.theme_type_variation = &"SubtitleLabel"
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm.add_child(question)
	_yes = _button(_confirm, "UI_YES", func() -> void: _pending.emit())
	_no = _button(_confirm, "UI_NO", _show_buttons)

	stats_panel = StatsPanel.new()
	stats_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(stats_panel)

	_settings = SettingsScreen.new()
	_settings.closed.connect(_on_settings_closed)
	root.add_child(_settings)


func open() -> void:
	visible = true
	_show_buttons()
	_resume.grab_focus()
	UiFx.pop_in(_panel)


func close() -> void:
	_settings.close()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _settings.visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if _confirm.visible:
			_show_buttons()
		else:
			resume_requested.emit()


func _button(parent: Container, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 64)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _ask(request: Signal, from: Button) -> void:
	_pending = request
	_pending_button = from
	_buttons.visible = false
	_confirm.visible = true
	_no.grab_focus()


func _show_buttons() -> void:
	_confirm.visible = false
	_buttons.visible = true
	if _pending_button != null:
		_pending_button.grab_focus()
		_pending_button = null


func _open_settings() -> void:
	_panel.visible = false
	stats_panel.visible = false
	_settings.open()


func _on_settings_closed() -> void:
	_panel.visible = true
	stats_panel.visible = true
	_settings_button.grab_focus()
