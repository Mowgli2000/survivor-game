class_name OrbitBehavior
extends WeaponBehavior
## Blades circling the owner for good (Shadow blades). Each blade is a projectile that follows the owner
## (ProjectileManager._orbit), passes through everything and hurts what it touches again every `rehit_time`
## (faster with rank and attack speed). Nothing to wait for: `fire` only keeps the blades right once per cooldown
## (spawns them when an enemy shows up, replaces them when their number changes, refreshes their damage and
## size from the owner's current stats).

## Orbit angular speed, radians per second (negative = counter-clockwise).
@export var orbit_speed: float = 3.4
## Blades only come out when an enemy is on screen.
const WAKE_DISTANCE := 800.0
## A blade lives "forever": it ends with its weapon, not with a timer.
const FOREVER := 1.0e9


func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool:
	var s := slot.stats
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var count := s.projectile_count + int(stats.get_value(StatIds.PROJECTILE_COUNT))
	var radius := s.attack_range  # the Range stat does not apply: the orbit is a fixed ring around the hero
	var area := 1.0  # the explosion size stat does not apply to the blades (ADR 0029)
	var knockback := s.knockback * stats.get_value(StatIds.KNOCKBACK)
	# Ranks and the attack speed stat make the blades turn and strike faster (the weapon's base cooldown is its pace 1).
	var pace := slot.data.cooldown / maxf(s.cooldown, 0.05) * maxf(stats.get_value(StatIds.ATTACK_SPEED), 0.1)
	var rehit := s.rehit_time / pace
	var blades := ctx.projectiles.orbit_blades(slot)
	var respawned := false
	var start := ctx.rng.randf() * TAU
	if blades.size() != count:
		if blades.is_empty() and ctx.enemies.find_nearest(origin, WAKE_DISTANCE) < 0:
			return false
		if not blades.is_empty():
			start = blades[0].orbit_angle
			for old in blades:
				old.life = 0.0
		for i in count:
			var blade := ctx.projectiles.spawn(origin, Vector2.ZERO, 0.0, false, 1000000, 0.0, area, s)
			blade.life = FOREVER
			blade.orbit_owner = ctx.owner
			blade.orbit_slot = slot
			blade.orbit_angle = start + TAU * i / count
			blade.rehit_left = rehit
		blades = ctx.projectiles.orbit_blades(slot)
		respawned = true
	slot.quiet = not respawned
	for blade in blades:
		var crit := ctx.roll_crit(s)
		blade.damage = ctx.hit_damage(s, crit)
		blade.crit = crit
		blade.knockback = knockback
		blade.radius = s.projectile_radius * area
		blade.half_length = s.hit_half_length * area
		blade.orbit_radius = radius
		blade.orbit_speed = orbit_speed * pace
		blade.rehit_time = rehit
	return true
