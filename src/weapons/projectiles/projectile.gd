class_name Projectile
extends RefCounted
## Plain projectile state (not a node). A manager moves it, resolves its hits
## and draws all projectiles at once through a ProjectileRenderer.

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
var bounces_left: int = 0
var bounce_range: float = 0.0
var explosion_radius: float = 0.0
var status: StatusData
var status_chance: float = 0.0
## Instance ids of enemies already hit (a projectile hits each enemy once).
var hit_ids: Array[int] = []


## Player projectile fired by a weapon. `area_multiplier` scales explosions.
func reset(pos: Vector2, p_velocity: Vector2, p_damage: float, p_crit: bool, pierce: int,
		p_knockback: float, area_multiplier: float, weapon: WeaponStats) -> void:
	reset_basic(pos, p_velocity, p_damage, weapon.projectile_radius, weapon.projectile_lifetime,
		CRIT_COLOR if p_crit else weapon.color)
	crit = p_crit
	pierce_left = pierce
	knockback = p_knockback
	bounces_left = weapon.bounces
	bounce_range = weapon.bounce_range
	explosion_radius = weapon.explosion_radius * area_multiplier
	status = weapon.status
	status_chance = weapon.status_chance


## Projectile without special features (enemy shots).
func reset_basic(pos: Vector2, p_velocity: Vector2, p_damage: float, p_radius: float,
		lifetime: float, p_color: Color) -> void:
	position = pos
	velocity = p_velocity
	damage = p_damage
	radius = p_radius
	life = lifetime
	color = p_color
	crit = false
	pierce_left = 0
	knockback = 0.0
	bounces_left = 0
	bounce_range = 0.0
	explosion_radius = 0.0
	status = null
	status_chance = 0.0
	hit_ids.clear()
