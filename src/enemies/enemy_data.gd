class_name EnemyData
extends Resource
## Definition of an enemy type. Instances live in data/enemies/.

enum Movement {
	CHASE,   ## Runs straight at the player.
	RANGED,  ## Keeps its distance, strafes and shoots.
}

@export var id: StringName
@export var name_key: String
@export var movement: Movement = Movement.CHASE

@export_group("Stats")
@export var max_hp: float = 10.0
@export var speed: float = 100.0
@export var contact_damage: float = 5.0
@export var armor: float = 0.0
@export var radius: float = 16.0
## 1.0 = normal knockback, 0.0 = immune.
@export var knockback_taken: float = 1.0

@export_group("Ranged attack")
@export var preferred_distance: float = 380.0
@export var fire_cooldown: float = 2.5
@export var projectile_damage: float = 8.0
@export var projectile_speed: float = 300.0
@export var projectile_radius: float = 9.0

@export_group("Rewards")
@export var xp_value: int = 1

@export_group("Visual (placeholder)")
## Neon outline color; the body is a dark version of it.
@export var color: Color = Color(0.9, 0.3, 0.3)
## 0 = circle, otherwise number of polygon sides (3 = triangle...).
@export var shape_sides: int = 0

var _texture: Texture2D


## Placeholder neon sprite of this enemy type, baked on first use (see EnemyArt).
func get_texture() -> Texture2D:
	if _texture == null:
		_texture = EnemyArt.bake(self)
	return _texture
