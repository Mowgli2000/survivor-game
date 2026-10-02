class_name MeleeArcBehavior
extends WeaponBehavior
## Slashes an arc in front of the player, toward the nearest enemy.
## Radius = weapon area, opening = arc_degrees. Extra "projectiles" add slashes
## evenly spread around the player (2 = front and back).


func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool:
	var s := slot.stats
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var target := ctx.enemies.find_nearest(origin, s.attack_range * stats.get_value(StatIds.RANGE))
	if target < 0:
		return false

	var direction := (ctx.enemies.get_enemy(target).position - origin).normalized()
	var radius := s.area * stats.get_value(StatIds.AREA)
	var half_angle := deg_to_rad(s.arc_degrees) * 0.5
	var min_dot := cos(half_angle)
	var knockback := s.knockback * stats.get_value(StatIds.KNOCKBACK)
	var count := s.projectile_count + int(stats.get_value(StatIds.PROJECTILE_COUNT))

	for i in count:
		var slash_dir := direction.rotated(TAU * i / count)
		var crit := ctx.roll_crit(s)
		ctx.enemies.damage_in_radius(origin, radius, ctx.hit_damage(s, crit), crit, knockback,
			s.status, s.status_chance, slash_dir, min_dot)
		if ctx.vfx != null:
			ctx.vfx.slash(origin, slash_dir.angle(), radius, half_angle, s.color)
	return true
