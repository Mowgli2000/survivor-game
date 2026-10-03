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
	dim.color = UiTheme.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.theme_type_variation = &"TitleLabel"
	center.add_child(_title)


func open(wave: int) -> void:
	_title.text = tr("UI_WAVE_CLEARED") % wave
	visible = true
	UiFx.pop_in(_title)


func close() -> void:
	visible = false
