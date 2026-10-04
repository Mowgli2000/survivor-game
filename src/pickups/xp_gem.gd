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
	# Mana crystal (art bible): bigger and more violet as the value grows (merged gems).
	var t := clampf(log(float(value)) / log(50.0), 0.0, 1.0)
	var color := Color(0.35, 0.78, 1.0).lerp(Color(0.68, 0.45, 1.0), t)
	var s := SIZE * (1.0 + t)
	var points := PackedVector2Array([Vector2(0, -s), Vector2(s * 0.7, 0), Vector2(0, s), Vector2(-s * 0.7, 0)])
	draw_colored_polygon(points, color)
	# Lit facet, then the black outline of the art style (no antialiasing: mass pickups).
	draw_colored_polygon(PackedVector2Array([Vector2(0, -s), Vector2(s * 0.7, 0), Vector2(0, 0)]), color.lerp(Color.WHITE, 0.55))
	points.append(points[0])
	draw_polyline(points, Color(0.05, 0.04, 0.1), 2.0)
