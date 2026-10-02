class_name Arena
extends Node2D
## Arena: tiled ground texture tinted a soft blue-violet (bright, not dark),
## faint neon grid to feel the movement, glowing border.

const GROUND := preload("res://assets/sprites/ground.png")
const OUTSIDE_COLOR := Color(0.1, 0.09, 0.16)
## Multiplies the white ground texture: soft blue-violet, not dark.
const FLOOR_TINT := Color(0.42, 0.42, 0.62)
const LINE_COLOR := Color(0.55, 0.65, 1.0, 0.12)
const BORDER_COLOR := Color(1.0, 0.2, 0.6)
const LINE_SPACING := 128.0

var rect: Rect2


func setup(p_rect: Rect2) -> void:
	rect = p_rect
	z_index = -10
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()


func _draw() -> void:
	draw_rect(rect.grow(2000.0), OUTSIDE_COLOR)
	draw_texture_rect(GROUND, rect, true, FLOOR_TINT)
	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), LINE_COLOR, 2.0)
		x += LINE_SPACING
	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), LINE_COLOR, 2.0)
		y += LINE_SPACING
	draw_rect(rect, Color(BORDER_COLOR, 0.12), false, 28.0)
	draw_rect(rect, Color(BORDER_COLOR, 0.3), false, 12.0)
	draw_rect(rect, BORDER_COLOR, false, 4.0)
