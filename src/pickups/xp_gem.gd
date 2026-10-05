class_name XpGem
extends Node2D
## Passive XP pickup. Updated by PickupManager.

const SIZE := 7.0
## Illustrated mana crystal (art bible style), drawn ~2x smaller than its texture.
const TEXTURE := preload("res://assets/sprites/pickups/crystal.png")
## Merged gems (big values) turn violet.
const BIG_TINT := Color(0.85, 0.62, 1.0)

var value: int = 1
var attracted: bool = false
var speed: float = 0.0
## Player number the gem flies to once attracted.
var target: int = 0


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


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
	var height := SIZE * 3.2 * (1.0 + t)
	var width := height * TEXTURE.get_width() / TEXTURE.get_height()
	draw_texture_rect(TEXTURE, Rect2(-width * 0.5, -height * 0.5, width, height), false,
		Color.WHITE.lerp(BIG_TINT, t))
