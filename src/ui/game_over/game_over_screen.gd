class_name GameOverScreen
extends CanvasLayer
## Shown when the player dies: run summary + retry button.

signal retry_requested

var _summary: Label
var _retry: Button


func _init() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.1, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	center.add_child(box)

	var title := Label.new()
	title.text = "UI_GAME_OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	box.add_child(title)

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


func open(time_survived: float, level: int, kills: int) -> void:
	_summary.text = "%s %s\n%s %d\n%s %d" % [
		tr("UI_TIME_SURVIVED"), Hud.format_time(time_survived),
		tr("UI_LEVEL_LABEL"), level,
		tr("UI_KILLS"), kills,
	]
	visible = true
	_retry.grab_focus()
