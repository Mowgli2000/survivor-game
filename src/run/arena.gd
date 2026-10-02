class_name Arena
extends Node2D
## Placeholder arena: floor, grid lines (to feel the movement) and border.

const FLOOR_COLOR := Color(0.11, 0.12, 0.15)
const LINE_COLOR := Color(0.16, 0.17, 0.21)
const BORDER_COLOR := Color(0.55, 0.25, 0.3)
const LINE_SPACING := 128.0

var rect: Rect2


func setup(p_rect: Rect2) -> void:
	rect = p_rect
	z_index = -10
	queue_redraw()


func _draw() -> void:
	draw_rect(rect.grow(2000.0), Color(0.05, 0.05, 0.07))
	draw_rect(rect, FLOOR_COLOR)
	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), LINE_COLOR, 2.0)
		x += LINE_SPACING
	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), LINE_COLOR, 2.0)
		y += LINE_SPACING
	draw_rect(rect, BORDER_COLOR, false, 8.0)
