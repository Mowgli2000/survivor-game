class_name ArrivalGate
extends Node2D
## The big gate the heroes drop out of when a run starts (after the seal screen's
## portal zoom): a procedural vortex (arrival_gate.gdshader) on one quad. It opens,
## stays while the heroes fall and closes behind them, then frees itself.

const SHADER := preload("res://src/run/arrival_gate.gdshader")
const OPEN_SECONDS := 0.5
const CLOSE_SECONDS := 0.7
## The shader shows this many gate radii from the center to the quad's edge.
const VIEW_RADII := 1.6
const TEXTURE_SIZE := 4

var _stay: float = 1.0
var _time: float = 0.0
var _sprite: Sprite2D
var _material: ShaderMaterial


## `radius` in px; `stay`: seconds it stays fully open after opening.
func setup(radius: float, stay: float) -> void:
	_stay = stay
	z_index = 1
	var texture := GradientTexture2D.new()
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.scale = Vector2.ONE * (2.0 * VIEW_RADII * radius / TEXTURE_SIZE)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"open", 0.0)
	_sprite.material = _material
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	if _time > OPEN_SECONDS + _stay + CLOSE_SECONDS:
		queue_free()
		return
	var opening := clampf(_time / OPEN_SECONDS, 0.0, 1.0)
	var closing := clampf((_time - OPEN_SECONDS - _stay) / CLOSE_SECONDS, 0.0, 1.0)
	# Quick start, soft landing on both ends.
	var open := (1.0 - pow(1.0 - opening, 3.0)) * (1.0 - closing * closing)
	_material.set_shader_parameter(&"open", open)
