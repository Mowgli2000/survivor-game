class_name WorldGrade
extends CanvasLayer
## Soft vignette over the arena (theme T3, ADR 0024): the corners darken so the HUD reads
## well. The arena keeps its own colors (TINT is white: the blue grade was removed on the
## dev's request, 2026-10-09). Under the HUD (layer 5), over the world, never intercepts input.

const LAYER := 5
## Modulate of the Arena node (white = the map's original colors).
const TINT := Color.WHITE
const VIGNETTE_ALPHA := 0.6


func _ready() -> void:
	layer = LAYER
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(0.0, 0.02, 0.08, 1.0))
	gradient.add_point(0.6, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.9)
	texture.width = 128
	texture.height = 128
	var vignette := TextureRect.new()
	vignette.texture = texture
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.modulate.a = VIGNETTE_ALPHA
	add_child(vignette)
