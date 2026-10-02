class_name WeaponData
extends Resource
## Definition of a weapon. Instances live in data/weapons/.
## The behavior decides how the weapon fires; the values below are its tuning.

@export var id: StringName
@export var name_key: String
@export var behavior: WeaponBehavior

@export_group("Stats")
@export var base_damage: float = 5.0
## Seconds between two shots at 100 % attack speed.
@export var cooldown: float = 1.0
@export var attack_range: float = 500.0
@export var crit_chance: float = 0.05
@export var knockback: float = 100.0

@export_group("Projectiles")
@export var projectile_speed: float = 600.0
@export var projectile_count: int = 1
## Angle in degrees between two projectiles of the same volley.
@export var spread_deg: float = 10.0
@export var pierce: int = 0
@export var projectile_radius: float = 6.0
@export var projectile_lifetime: float = 1.0

@export_group("Visual (placeholder)")
@export var color: Color = Color(1.0, 0.9, 0.4)
