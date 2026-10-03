class_name XpGem
extends Node2D
## Passive XP pickup. Updated by PickupManager.

const SIZE := 7.0

var value: int = 1
var attracted: bool = false
var speed: float = 0.0
## Player number the gem flies to once attracted.
var target: int = 0


func reset(pos: Vector2, p_value: int) -> void:
	position = pos
	value = p_value
	attracted = false
	target = 0
	speed = 0.0
	visible = true
	queue_redraw()


func add_value(amount: int) -> void:
	value += amount
	queue_redraw()


func _draw() -> void:
	# Bigger and bluer as the value grows (merged gems).
	var t := clampf(log(float(value)) / log(50.0), 0.0, 1.0)
	var color := Color(0.35, 1.0, 0.5).lerp(Color(0.5, 0.6, 1.0), t)
	var s := SIZE * (1.0 + t)
	var points := PackedVector2Array([Vector2(0, -s), Vector2(s * 0.7, 0), Vector2(0, s), Vector2(-s * 0.7, 0)])
	draw_colored_polygon(points, color)
