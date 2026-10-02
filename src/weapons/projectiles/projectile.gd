class_name Projectile
extends RefCounted
## Plain projectile state (not a node). ProjectileManager moves it, resolves its
## hits and renders every projectile in a single MultiMesh draw call.

const CRIT_COLOR := Color(1.0, 0.45, 0.2)

var position := Vector2.ZERO
var velocity := Vector2.ZERO
var damage: float = 0.0
var crit: bool = false
var pierce_left: int = 0
var knockback: float = 0.0
var radius: float = 6.0
var life: float = 0.0
var color := Color.WHITE
## Instance ids of enemies already hit (a piercing projectile hits each enemy once).
var hit_ids: Array[int] = []


func reset(pos: Vector2, p_velocity: Vector2, p_damage: float, p_crit: bool, pierce: int,
		p_knockback: float, p_radius: float, lifetime: float, p_color: Color) -> void:
	position = pos
	velocity = p_velocity
	damage = p_damage
	crit = p_crit
	pierce_left = pierce
	knockback = p_knockback
	radius = p_radius
	life = lifetime
	color = CRIT_COLOR if p_crit else p_color
	hit_ids.clear()
