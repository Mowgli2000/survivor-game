class_name GameOverScreen
extends CanvasLayer
## Shown when the run ends (death or victory): run summary + retry button.

signal retry_requested

## True when the last open() was a victory.
var is_victory: bool = false

var _title: Label
var _dim: ColorRect
var _summary: Label
var _retry: Button


func _init() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)

	_dim = ColorRect.new()
	_dim.color = Color(0.1, 0, 0, 0.75)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	center.add_child(box)

	_title = Label.new()
	_title.text = "UI_GAME_OVER"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 80)
	box.add_child(_title)

	_summary = Label.new()
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.add_theme_font_size_override("font_size", 32)
	box.add_child(_summary)

	_retry = Button.new()
	_retry.text = "UI_RETRY"
	_retry.custom_minimum_size = Vector2(320, 80)
	_retry.add_theme_font_size_override("font_size", 36)
	_retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	box.add_child(_retry)


func open(time_survived: float, level: int, kills: int, wave: int, victory: bool = false) -> void:
	is_victory = victory
	_title.text = "UI_VICTORY" if victory else "UI_GAME_OVER"
	_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if victory else Color.WHITE)
	_dim.color = Color(0.0, 0.06, 0.08, 0.8) if victory else Color(0.1, 0, 0, 0.75)
	_summary.text = "%s %d\n%s %s\n%s %d\n%s %d" % [
		tr("UI_WAVE_REACHED"), wave,
		tr("UI_TIME_SURVIVED"), Hud.format_time(time_survived),
		tr("UI_LEVEL_LABEL"), level,
		tr("UI_KILLS"), kills,
	]
	visible = true
	_retry.grab_focus()
