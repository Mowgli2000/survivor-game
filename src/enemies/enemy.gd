class_name Enemy
extends Node2D
## Passive enemy: data + placeholder visual. Moved and damaged by EnemyManager
## (no _process here, see ADR 0002).
## The shape is drawn once in white and tinted with self_modulate, so the hit
## flash only changes the tint and never triggers a redraw.

const FLASH_TIME := 0.08
const OUTLINE_COLOR := Color(0.05, 0.05, 0.08)

var data: EnemyData
var hp: float = 0.0
var max_hp: float = 0.0
var radius: float = 16.0
var knockback := Vector2.ZERO
var flash: float = 0.0


func reset(p_data: EnemyData, pos: Vector2, hp_multiplier: float) -> void:
	var data_changed := data != p_data
	data = p_data
	position = pos
	max_hp = data.max_hp * hp_multiplier
	hp = max_hp
	radius = data.radius
	knockback = Vector2.ZERO
	flash = 0.0
	rotation = 0.0
	self_modulate = data.color
	visible = true
	if data_changed:
		queue_redraw()


func is_alive() -> bool:
	return hp > 0.0


func set_flash(value: float) -> void:
	var was_flashing := flash > 0.0
	flash = value
	if was_flashing != (flash > 0.0):
		self_modulate = Color.WHITE * 1.6 if flash > 0.0 else data.color


func _draw() -> void:
	if data == null:
		return
	if data.shape_sides >= 3:
		var points := data.get_polygon()
		draw_colored_polygon(points, Color.WHITE)
		draw_polyline(points + PackedVector2Array([points[0]]), OUTLINE_COLOR, 2.0)
	else:
		draw_circle(Vector2.ZERO, radius, Color.WHITE)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, OUTLINE_COLOR, 2.0)
