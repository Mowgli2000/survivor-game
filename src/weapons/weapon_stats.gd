class_name WeaponStats
extends RefCounted
## Effective values of a weapon at a given level (WeaponData + its levels).
## Player stats (damage, attack speed, area...) are applied on top by behaviors.

var damage: float
var cooldown: float
var attack_range: float
var crit_chance: float
var knockback: float
var projectile_speed: float
var projectile_count: int
var spread_deg: float
var inaccuracy_deg: float
var pierce: int
var projectile_radius: float
var projectile_lifetime: float
var bounces: int
var bounce_range: float
var explosion_radius: float
var area: float
var arc_degrees: float
var status: StatusData
var status_chance: float
var color: Color


static func compute(data: WeaponData, level: int) -> WeaponStats:
	var s := WeaponStats.new()
	s.attack_range = data.attack_range
	s.crit_chance = data.crit_chance
	s.knockback = data.knockback
	s.projectile_speed = data.projectile_speed
	s.projectile_count = data.projectile_count
	s.spread_deg = data.spread_deg
	s.inaccuracy_deg = data.inaccuracy_deg
	s.pierce = data.pierce
	s.projectile_radius = data.projectile_radius
	s.projectile_lifetime = data.projectile_lifetime
	s.bounces = data.bounces
	s.bounce_range = data.bounce_range
	s.arc_degrees = data.arc_degrees
	s.status = data.status
	s.status_chance = data.status_chance
	s.color = data.color

	var damage_percent := 0.0
	var fire_rate_percent := 0.0
	var area_percent := 0.0
	for i in clampi(level - 1, 0, data.levels.size()):
		var bonus := data.levels[i]
		damage_percent += bonus.damage_percent
		fire_rate_percent += bonus.fire_rate_percent
		area_percent += bonus.area_percent
		s.projectile_count += bonus.projectile_count
		s.pierce += bonus.pierce
		s.bounces += bonus.bounces
	s.damage = data.base_damage * (1.0 + damage_percent)
	s.cooldown = data.cooldown / maxf(1.0 + fire_rate_percent, 0.1)
	s.area = data.area * (1.0 + area_percent)
	s.explosion_radius = data.explosion_radius * (1.0 + area_percent)
	return s
