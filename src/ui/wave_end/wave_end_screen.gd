class_name WaveEndScreen
extends CanvasLayer
## Between waves: "Wave X cleared", then (after the level-up choices handled by
## Run) a "Next wave" button. The shop will slot in here in Phase 5.

signal next_wave_requested

var _title: Label
var _next: Button


func _init() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0.02, 0.06, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 48)
	center.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 72)
	_title.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
	box.add_child(_title)

	_next = Button.new()
	_next.text = "UI_NEXT_WAVE"
	_next.custom_minimum_size = Vector2(380, 80)
	_next.add_theme_font_size_override("font_size", 36)
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next.pressed.connect(func() -> void: next_wave_requested.emit())
	box.add_child(_next)


func open(wave: int) -> void:
	_title.text = tr("UI_WAVE_CLEARED") % wave
	_next.visible = false
	visible = true


## Shown once every pending level-up has been chosen.
func show_next_button() -> void:
	_next.visible = true
	_next.grab_focus()


func close() -> void:
	visible = false
