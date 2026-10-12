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
## WeaponData.ProjectileStyle (0 = glow only).
var style: int = 0
## Turn rate toward the nearest enemy, radians/s (0 = straight).
var homing: float = 0.0
var bounces_left: int = 0
var bounce_range: float = 0.0
var explosion_radius: float = 0.0
## Shards the explosion throws outward (see WeaponData.fragments).
var fragments: int = 0
## Lobbed bomb: seconds it burns on the ground after landing (`fused` once it landed).
var fuse: float = 0.0
var fused: bool = false
## Bounces still to make to another enemy after exploding (explosive flask).
var rebounds: int = 0
## Burning ground left where it explodes: seconds, and its painted loop.
var zone_time: float = 0.0
var zone_sheet: EffectSheet
var zone_end_sheet: EffectSheet
var zone_radius: float = 0.0
var fragment_style: int = 0
## Stays on its enemies: they are hit again every `rehit_time` seconds (0 = each enemy once).
var rehit_time: float = 0.0
var rehit_left: float = 0.0
## Vortex: drags the enemies within `pull_radius` toward itself.
var pull_radius: float = 0.0
var pull_speed: float = 0.0
var landing_blast: bool = true
var blast_on_pierce: bool = false
## Damage gained over the flight (share at `range_ref` px from `start`), see WeaponData.distance_damage.
var distance_damage: float = 0.0
var range_ref: float = 1.0
var start := Vector2.ZERO
## Boomerang: `returns` = it comes back to `return_to` once its flight is over (`coming_back` while it does).
var returns: bool = false
var coming_back: bool = false
var return_to: Node2D
var wall_bounces: int = 0
## Orbiting blade: circles `orbit_owner` at `orbit_radius` px, `orbit_speed` radians/s, `orbit_angle` now.
var orbit_owner: Node2D
## The weapon slot an orbiting blade belongs to (it follows that slot's stats and ends with it).
var orbit_slot: WeaponSlot
## Capsule hit shape: half length of the segment along the travel (0 = a plain circle).
var half_length: float = 0.0
var orbit_angle: float = 0.0
var orbit_radius: float = 0.0
var orbit_speed: float = 0.0
var status: StatusData
var status_chance: float = 0.0
## Instance ids of enemies already hit (a projectile hits each enemy once).
var hit_ids: Array[int] = []
## Lobbed shot (flask, bomb, grenade): flies in an arc over `lob_total` seconds and explodes where it lands,
## touching nothing on the way. `lob_peak` = height of the arc in px (0 = a straight shot).
var lob_peak: float = 0.0
var lob_total: float = 0.0


## Player projectile fired by a weapon. `area_multiplier` scales explosions.
## Player who fired it: EnemyManager.damage_source of its hits (ADR 0017).
var source: int = 0
## Weapon id that fired it (end-of-run damage summary).
var weapon: StringName = &""

func reset(pos: Vector2, p_velocity: Vector2, p_damage: float, p_crit: bool, pierce: int,
		p_knockback: float, area_multiplier: float, weapon: WeaponStats,
		range_multiplier: float = 1.0) -> void:
	# The range stat stretches the flight too: a weapon never aims farther than it can reach.
	reset_basic(pos, p_velocity, p_damage, weapon.projectile_radius,
		weapon.projectile_lifetime * maxf(range_multiplier, 1.0),
		CRIT_COLOR if p_crit else weapon.color)
	crit = p_crit
	style = weapon.projectile_style
	homing = weapon.homing
	pierce_left = pierce
	knockback = p_knockback
	bounces_left = weapon.bounces
	bounce_range = weapon.bounce_range
	explosion_radius = weapon.explosion_radius * area_multiplier
	fragments = weapon.fragments
	fuse = weapon.fuse_time
	fused = false
	rebounds = weapon.rebounds
	zone_time = weapon.zone_time
	zone_sheet = weapon.zone_sheet
	zone_end_sheet = weapon.zone_end_sheet
	zone_radius = weapon.zone_radius
	fragment_style = weapon.fragment_style
	rehit_time = weapon.rehit_time
	pull_radius = weapon.pull_radius
	pull_speed = weapon.pull_speed
	landing_blast = weapon.landing_blast
	blast_on_pierce = weapon.blast_on_pierce
	distance_damage = weapon.distance_damage
	range_ref = maxf(weapon.attack_range * maxf(range_multiplier, 1.0), 1.0)
	start = pos
	returns = weapon.returns
	wall_bounces = weapon.wall_bounces
	status = weapon.status
	status_chance = weapon.status_chance


## Projectile without special features (enemy shots).
func reset_basic(pos: Vector2, p_velocity: Vector2, p_damage: float, p_radius: float,
		lifetime: float, p_color: Color, p_style: int = 0) -> void:
	position = pos
	velocity = p_velocity
	damage = p_damage
	radius = p_radius
	life = lifetime
	color = p_color
	style = p_style
	homing = 0.0
	crit = false
	pierce_left = 0
	knockback = 0.0
	bounces_left = 0
	bounce_range = 0.0
	explosion_radius = 0.0
	fuse = 0.0
	fused = false
	rebounds = 0
	zone_time = 0.0
	zone_sheet = null
	zone_end_sheet = null
	zone_radius = 0.0
	fragments = 0
	fragment_style = 0
	rehit_time = 0.0
	rehit_left = 0.0
	pull_radius = 0.0
	pull_speed = 0.0
	landing_blast = true
	blast_on_pierce = false
	distance_damage = 0.0
	range_ref = 1.0
	start = pos
	returns = false
	coming_back = false
	return_to = null
	wall_bounces = 0
	orbit_owner = null
	orbit_slot = null
	half_length = 0.0
	orbit_angle = 0.0
	orbit_radius = 0.0
	orbit_speed = 0.0
	status = null
	status_chance = 0.0
	hit_ids.clear()
	lob_peak = 0.0
	lob_total = 0.0

