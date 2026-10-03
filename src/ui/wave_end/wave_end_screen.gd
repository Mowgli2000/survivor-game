class_name WaveEndScreen
extends CanvasLayer
## Between waves: "Wave X cleared" title, shown behind the level-up cards.
## The shop follows (ShopScreen).

var _title: Label


func _init() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0.02, 0.06, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 72)
	_title.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
	center.add_child(_title)


func open(wave: int) -> void:
	_title.text = tr("UI_WAVE_CLEARED") % wave
	visible = true


func close() -> void:
	visible = false
