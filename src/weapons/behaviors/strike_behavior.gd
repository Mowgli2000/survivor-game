class_name StrikeBehavior
extends WeaponBehavior
## Strike from the sky (meteors): each "projectile" lands instantly on an enemy
## picked around a random spot in range (not always the nearest one), hitting
## everything within the weapon's area. A streak falls on the impact point.
## Counts as a ranged weapon (WeaponData.is_melee).

## Where the streak starts, relative to the impact point.
const STREAK_FROM := Vector2(-90.0, -320.0)


func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool:
	var s := slot.stats
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var reach := s.attack_range * stats.get_value(StatIds.RANGE)
	if ctx.enemies.find_nearest(origin, reach) < 0:
		return false
	var radius := s.area * stats.get_value(StatIds.AREA)
	var knockback := s.knockback * stats.get_value(StatIds.KNOCKBACK)
	var count := s.projectile_count + int(stats.get_value(StatIds.PROJECTILE_COUNT))
	for i in count:
		var target := _pick_target(ctx, origin, reach)
		if target < 0:
			continue
		var point := ctx.enemies.get_enemy(target).position
		var crit := ctx.roll_crit(s)
		ctx.enemies.damage_in_radius(point, radius, ctx.hit_damage(s, crit), crit, knockback,
			s.status, s.status_chance)
		if ctx.vfx != null:
			ctx.vfx.beam(point + STREAK_FROM, point, radius * 0.35, s.color)
			ctx.vfx.explosion(point, radius, s.color, false)
	return true


## Enemy nearest to a random spot within reach (falls back to the nearest one).
func _pick_target(ctx: WeaponContext, origin: Vector2, reach: float) -> int:
	if ctx.rng != null:
		var probe := origin + Vector2.from_angle(ctx.rng.randf() * TAU) * ctx.rng.randf_range(0.0, reach * 0.7)
		var target := ctx.enemies.find_nearest(probe, reach * 0.5)
		if target >= 0 and ctx.enemies.get_enemy(target).position.distance_to(origin) <= reach:
			return target
	return ctx.enemies.find_nearest(origin, reach)
