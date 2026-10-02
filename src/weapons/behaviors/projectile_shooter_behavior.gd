class_name ProjectileShooterBehavior
extends WeaponBehavior
## Shoots a fan of projectiles at the nearest enemy in range.
## Projectile features (pierce, bounces, explosion, status) come from the weapon stats.


func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool:
	var s := slot.stats
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var target := ctx.enemies.find_nearest(origin, s.attack_range * stats.get_value(StatIds.RANGE))
	if target < 0:
		return false

	var base_angle := (ctx.enemies.get_enemy(target).position - origin).angle()
	var count := s.projectile_count + int(stats.get_value(StatIds.PROJECTILE_COUNT))
	var spread := deg_to_rad(s.spread_deg)
	var inaccuracy := deg_to_rad(s.inaccuracy_deg)
	var speed := s.projectile_speed * stats.get_value(StatIds.PROJECTILE_SPEED)
	var pierce := s.pierce + int(stats.get_value(StatIds.PIERCE))
	var knockback := s.knockback * stats.get_value(StatIds.KNOCKBACK)
	var area := stats.get_value(StatIds.AREA)

	for i in count:
		var angle := base_angle + (i - (count - 1) * 0.5) * spread
		if inaccuracy > 0.0:
			angle += ctx.rng.randf_range(-inaccuracy, inaccuracy)
		var crit := ctx.roll_crit(s)
		ctx.projectiles.spawn(origin, Vector2.from_angle(angle) * speed, ctx.hit_damage(s, crit), crit,
			pierce, knockback, area, s)
	return true
