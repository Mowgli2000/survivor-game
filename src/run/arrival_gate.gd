class_name ArrivalGate
extends Node2D
## The gate the heroes walk out of when a run starts (after the seal screen's portal
## zoom). Seen three-quarter face: an upright vortex (arrival_gate.gdshader) squeezed
## into a tall ellipse, a glow on the floor under it. It appears, grows, stays while
## the heroes walk out, then closes and frees itself. In the color of the chosen seal (heat gradient, red for the last).

const SHADER := preload("res://src/run/arrival_gate.gdshader")
## The picture whose painted portal is read (the same one as the seal screen shows).
const PORTAL_PICTURE := preload("res://assets/ui/select/seal_gate_v3.png")
const OPEN_SECONDS := 0.9
const CLOSE_SECONDS := 0.6
## The shader shows this many gate radii from the center to the quad's edge.
const VIEW_RADII := 1.7
const TEXTURE_SIZE := 4
## Width of the gate against its height: turned three-quarters toward the camera.
const WIDTH_SHARE := 0.62
## Slight lean so it does not look stamped on the screen.
const LEAN := -0.1

## Default gate color (blue).
const BLUE_COLOR := Color(0.3, 0.6, 1.0)

var _stay: float = 1.0
var _time: float = 0.0
var _radius: float = 130.0
var _material: ShaderMaterial
var _glow: Sprite2D
var _glow_color := Color(0.3, 0.8, 1.0)


## `radius` in px (half the gate's height); `stay`: seconds it stays fully open once opened;
## `color`: the seal's portal color (DifficultyData.color).
func setup(radius: float, stay: float, color: Color = BLUE_COLOR) -> void:
	_radius = radius
	_stay = stay
	z_index = 1
	var palette := palette_for(color)
	_glow_color = palette[0]
	_glow = Sprite2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(_glow_color, 0.55))
	gradient.set_color(1, Color(_glow_color, 0.0))
	var glow_texture := GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(0.5, 0.0)
	glow_texture.width = 64
	glow_texture.height = 64
	_glow.texture = glow_texture
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	# A wide flat pool of light on the floor under the gate.
	_glow.position = Vector2(0.0, radius * 0.92)
	_glow.scale = Vector2(radius * 2.6 / 64.0, radius * 0.9 / 64.0)
	_glow.modulate.a = 0.0
	add_child(_glow)
	var texture := GradientTexture2D.new()
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(WIDTH_SHARE, 1.0) * (2.0 * VIEW_RADII * radius / TEXTURE_SIZE)
	sprite.rotation = LEAN
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"open", 0.0)
	_material.set_shader_parameter(&"vortex", PORTAL_PICTURE)
	_material.set_shader_parameter(&"mid", Vector3(palette[0].r, palette[0].g, palette[0].b))
	_material.set_shader_parameter(&"outer", Vector3(palette[1].r, palette[1].g, palette[1].b))
	_material.set_shader_parameter(&"deep", Vector3(palette[2].r, palette[2].g, palette[2].b))
	sprite.material = _material
	add_child(sprite)


## Shader palette of a gate color: bright bands, outer body, deepest shade.
static func palette_for(color: Color) -> Array[Color]:
	return [color.lerp(Color.WHITE, 0.3), color.darkened(0.2), Color(color.r * 0.07, color.g * 0.07, color.b * 0.07 + 0.02)]


## Seconds from the start until the gate is gone.
static func total_seconds(stay: float) -> float:
	return OPEN_SECONDS + stay + CLOSE_SECONDS


func _process(delta: float) -> void:
	_time += delta
	if _time > total_seconds(_stay):
		queue_free()
		return
	var opening := clampf(_time / OPEN_SECONDS, 0.0, 1.0)
	var closing := clampf((_time - OPEN_SECONDS - _stay) / CLOSE_SECONDS, 0.0, 1.0)
	# It appears (a quick bloom) and grows; at the end it shrinks back into itself.
	var open := (1.0 - pow(1.0 - opening, 3.0)) * (1.0 - closing * closing)
	_material.set_shader_parameter(&"open", open)
	_glow.modulate.a = open * (0.75 + 0.25 * sin(_time * 7.0))
