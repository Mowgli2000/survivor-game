class_name MenuCrowd
extends Node2D
## Main menu decoration: a few enemies wandering slowly inside `rect`.
## One node draws them all; no EnemyManager (nothing to fight).

const COUNT := 10
const SPEED := 45.0

var _rect: Rect2
var _rng := RandomNumberGenerator.new()
var _sheets: Array[SpriteSheet] = []
var _heights: PackedFloat32Array = []
var _tints: PackedColorArray = []
var _positions: PackedVector2Array = []
var _directions: PackedVector2Array = []
var _time: float = 0.0


func setup(rect: Rect2, enemies: Array[EnemyData]) -> void:
	_rect = rect
	var pool: Array[EnemyData] = []
	for data in enemies:
		if not data.boss and data.get_sheet(false) != null:
			pool.append(data)
	if pool.is_empty():
		return
	for i in COUNT:
		var data := pool[i % pool.size()]
		_sheets.append(data.get_sheet(false))
		_heights.append(data.radius * Enemy.SPRITE_HEIGHT_PER_RADIUS * data.sprite_scale)
		_tints.append(data.sprite_tint)
		_positions.append(Vector2(_rng.randf_range(rect.position.x, rect.end.x),
			_rng.randf_range(rect.position.y, rect.end.y)))
		_directions.append(Vector2.from_angle(_rng.randf() * TAU))


func count() -> int:
	return _positions.size()


func _process(delta: float) -> void:
	_time += delta
	for i in _positions.size():
		_positions[i] += _directions[i] * SPEED * delta
		if not _rect.has_point(_positions[i]):
			var back := (_rect.get_center() - _positions[i]).normalized()
			_directions[i] = back.rotated(_rng.randf_range(-0.6, 0.6))
	queue_redraw()


func _draw() -> void:
	for i in _positions.size():
		var sheet := _sheets[i]
		draw_set_transform(_positions[i])
		sheet.draw(self, sheet.frame_at(&"walk", _time + i * 0.37), _heights[i], 0.0,
			_directions[i].x, _tints[i])
	draw_set_transform(Vector2.ZERO)
