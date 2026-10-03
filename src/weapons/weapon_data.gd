class_name WeaponData
extends Resource
## Definition of a weapon. Instances live in data/weapons/.
## The behavior decides how the weapon attacks; the values below are its tier I
## tuning, and `levels` describes what each following level adds.

@export var id: StringName
@export var name_key: String
@export var description_key: String
@export var behavior: WeaponBehavior
## Tiers II..IV: levels[0] = what tier II adds, levels[1] = tier III, levels[2] = tier IV.
@export var levels: Array[WeaponLevel] = []
## Shop price of the tier I weapon (higher tiers: ShopConfig.weapon_tier_price).
@export var base_price: int = 15

@export_group("Stats")
@export var base_damage: float = 5.0
## Seconds between two attacks at 100 % attack speed.
@export var cooldown: float = 1.0
## Distance at which the weapon looks for a target.
@export var attack_range: float = 500.0
@export var crit_chance: float = 0.05
@export var knockback: float = 100.0

@export_group("Projectiles")
@export var projectile_speed: float = 600.0
@export var projectile_count: int = 1
## Angle in degrees between two projectiles of the same volley.
@export var spread_deg: float = 10.0
## Random deviation in degrees applied to each projectile.
@export var inaccuracy_deg: float = 0.0
@export var pierce: int = 0
@export var projectile_radius: float = 6.0
@export var projectile_lifetime: float = 1.0
## Number of times a projectile jumps to another enemy after a hit.
@export var bounces: int = 0
@export var bounce_range: float = 300.0
## > 0: the projectile explodes on impact (or at the end of its life).
@export var explosion_radius: float = 0.0

@export_group("Area")
## Radius of a melee arc, or width of a beam.
@export var area: float = 0.0
## Opening of a melee arc, in degrees.
@export var arc_degrees: float = 120.0

@export_group("Status")
@export var status: StatusData
@export_range(0.0, 1.0) var status_chance: float = 1.0

@export_group("Audio")
@export var fire_sound: AudioStream
@export var fire_volume_db: float = -6.0

@export_group("Visual")
@export var color: Color = Color(1.0, 0.9, 0.4)
## Shop/HUD icon, also drawn as the in-game weapon (profile, barrel pointing right,
## centered). Null: text only in the UI, not drawn in game.
@export var icon: Texture2D


func max_level() -> int:
	return levels.size() + 1
