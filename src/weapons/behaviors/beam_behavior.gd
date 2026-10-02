class_name BeamBehavior
extends WeaponBehavior
## Instant beam toward the nearest enemy, hitting everything along its length
## (length = attack range, width = weapon area).


func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool:
	var s := slot.stats
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var length := s.attack_range * stats.get_value(StatIds.RANGE)
	var target := ctx.enemies.find_nearest(origin, length)
	if target < 0:
		return false

	var base_angle := (ctx.enemies.get_enemy(target).position - origin).angle()
	var count := s.projectile_count + int(stats.get_value(StatIds.PROJECTILE_COUNT))
	var spread := deg_to_rad(s.spread_deg)
	var width := s.area * stats.get_value(StatIds.AREA)
	var knockback := s.knockback * stats.get_value(StatIds.KNOCKBACK)

	for i in count:
		var angle := base_angle + (i - (count - 1) * 0.5) * spread
		var end := origin + Vector2.from_angle(angle) * length
		var crit := ctx.roll_crit(s)
		ctx.enemies.damage_along_segment(origin, end, width * 0.5, ctx.hit_damage(s, crit), crit,
			knockback, s.status, s.status_chance)
		if ctx.vfx != null:
			ctx.vfx.beam(origin, end, width, s.color)
	return true
