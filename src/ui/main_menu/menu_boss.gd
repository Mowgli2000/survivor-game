class_name MenuBoss
extends Node2D
## Main menu decoration: the demon knight standing in front of the gate, facing
## the menu. Drawn from the full-resolution illustration (the sprite atlas is
## too small for his size here: it looked blurry). A still picture.
## Node position = his feet.

const ILLUSTRATION := preload("res://assets/ui/menu_boss.png")
## The illustration looks to the right; the menu is on his left.
const FACING := -1.0

var height: float = 800.0


func is_ready() -> bool:
	return ILLUSTRATION != null


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var size := ILLUSTRATION.get_size()
	var width := height * size.x / size.y
	# A negative width mirrors the texture around x.
	draw_texture_rect(ILLUSTRATION, Rect2(-width * 0.5, -height, width * signf(FACING), height), false)
