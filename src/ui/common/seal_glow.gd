class_name SealGlow
extends Control
## Runic seal on the floor of the character select screens, separate from the background so it
## can be placed, sized and lit freely. Two painted layers (AI art, same shape, pixel-aligned):
## the dim engraved seal, always shown, and its "activated" version drawn over it with additive
## blending. `set_lit` fades the light up and down; while lit it breathes slowly.
## Display only. Colors: &"cyan" (hunter 1 and solo) and &"amber" (hunter 2).

const TEXTURES: Dictionary[StringName, Array] = {
	&"cyan": [preload("res://assets/ui/select/seal_base_cyan.png"), preload("res://assets/ui/select/seal_glow_cyan.png")],
	&"amber": [preload("res://assets/ui/select/seal_base_amber.png"), preload("res://assets/ui/select/seal_glow_amber.png")],
}
## Height of the painted ellipse's center in the picture (share of its height).
const CENTER_Y := 0.571
## The seal is drawn a little flatter than painted so it fits the floor of the pictures.
const SQUASH := 0.62
## Seconds for the light to fully rise / fall.
const RISE_SECONDS := 0.45
const FALL_SECONDS := 0.8
## Brightest the light gets (dev: 10-15 % under the first version) and how deep and how fast it
## breathes while lit (share of the light, rad/s): a clear glow up and glow down.
const MAX_LIGHT := 0.87
const BREATH_DEPTH := 0.45
const BREATH_SPEED := 3.0
## The engraved seal brightens a little with the light.
const BASE_DIM := 0.7

var lit: bool = false

var _base: TextureRect
var _glow: TextureRect
var _level: float = 0.0
var _time: float = 0.0


func _init(color_id: StringName = &"cyan") -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pair: Array = TEXTURES[color_id]
	_base = _layer(pair[0])
	_glow = _layer(pair[1])
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = additive
	_apply()


## Size of the seal for a given width (the picture's aspect, flattened by SQUASH).
static func size_for_width(width: float) -> Vector2:
	var texture: Texture2D = (TEXTURES[&"cyan"] as Array)[0]
	return Vector2(width, width * texture.get_height() / float(texture.get_width()) * SQUASH)


## Puts the seal with the center of its ellipse on `center` (parent coordinates).
func place(center: Vector2, width: float) -> void:
	size = size_for_width(width)
	position = center - Vector2(size.x * 0.5, size.y * CENTER_Y)


## Light level (0..1) at this moment (tests).
func level() -> float:
	return _level


func set_lit(on: bool) -> void:
	lit = on
	if UiFx.reduce_motion:
		_level = 1.0 if on else 0.0
		_apply()


func _process(delta: float) -> void:
	var target := 1.0 if lit else 0.0
	if is_equal_approx(_level, target) and not lit:
		return
	_time += delta
	if not UiFx.reduce_motion:
		_level = move_toward(_level, target, delta / (RISE_SECONDS if lit else FALL_SECONDS))
	_apply()


func _apply() -> void:
	var breath := 1.0
	if lit and not UiFx.reduce_motion:
		breath = 1.0 - BREATH_DEPTH * 0.5 * (1.0 + sin(_time * BREATH_SPEED))
	_glow.modulate.a = _level * MAX_LIGHT * breath
	_base.modulate.a = lerpf(BASE_DIM, 1.0, _level)


func _layer(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rect)
	return rect
