class_name EnemyData
extends Resource
## Definition of an enemy type. Instances live in data/enemies/.

@export var id: StringName
@export var name_key: String

@export_group("Stats")
@export var max_hp: float = 10.0
@export var speed: float = 100.0
@export var contact_damage: float = 5.0
@export var armor: float = 0.0
@export var radius: float = 16.0
## 1.0 = normal knockback, 0.0 = immune.
@export var knockback_taken: float = 1.0

@export_group("Rewards")
@export var xp_value: int = 1

@export_group("Visual (placeholder)")
@export var color: Color = Color(0.9, 0.3, 0.3)
## 0 = circle, otherwise number of polygon sides (3 = triangle...).
@export var shape_sides: int = 0

var _polygon_cache := PackedVector2Array()


## Shape points for the placeholder visual (cached, derived from exported values).
func get_polygon() -> PackedVector2Array:
	if _polygon_cache.is_empty() and shape_sides >= 3:
		for i in shape_sides:
			var angle := TAU * i / shape_sides
			_polygon_cache.append(Vector2.from_angle(angle) * radius)
	return _polygon_cache
