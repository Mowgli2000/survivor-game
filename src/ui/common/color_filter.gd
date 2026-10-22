class_name ColorFilter
extends CanvasLayer
## Full-screen colorblind correction (Settings `colorblind`: 0 off, 1 protanopia, 2 deuteranopia, 3 tritanopia).
## Drawn above everything, UI included. Hidden when off: no screen copy is paid then.

const SHADER := preload("res://src/ui/common/colorblind.gdshader")

var _material := ShaderMaterial.new()
var _rect := ColorRect.new()


func _init() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_material.shader = SHADER
	_rect.material = _material
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	add_child(_rect)


func set_mode(mode: int) -> void:
	_rect.visible = mode > 0
	_material.set_shader_parameter(&"mode", maxi(mode, 1))
