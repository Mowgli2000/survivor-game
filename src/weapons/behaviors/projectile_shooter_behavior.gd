class_name ProjectileShooterBehavior
extends WeaponBehavior
## Shoots a fan of projectiles at the nearest enemy in range.


func fire(weapon: WeaponData, ctx: WeaponContext) -> bool:
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var weapon_range := weapon.attack_range * stats.get_value(StatIds.RANGE)
	var target := ctx.enemies.find_nearest(origin, weapon_range)
	if target < 0:
		return false

	var base_angle := (ctx.enemies.get_enemy(target).position - origin).angle()
	var count := weapon.projectile_count + int(stats.get_value(StatIds.PROJECTILE_COUNT))
	var spread := deg_to_rad(weapon.spread_deg)
	var speed := weapon.projectile_speed * stats.get_value(StatIds.PROJECTILE_SPEED)
	var crit_chance := weapon.crit_chance + stats.get_value(StatIds.CRIT_CHANCE)
	var pierce := weapon.pierce + int(stats.get_value(StatIds.PIERCE))
	var knockback := weapon.knockback * stats.get_value(StatIds.KNOCKBACK)

	for i in count:
		var angle := base_angle + (i - (count - 1) * 0.5) * spread
		var crit := CombatMath.is_crit(crit_chance, ctx.rng.randf())
		var damage := CombatMath.outgoing_damage(
			weapon.base_damage, stats.get_value(StatIds.DAMAGE), crit, stats.get_value(StatIds.CRIT_DAMAGE))
		ctx.projectiles.spawn(origin, Vector2.from_angle(angle) * speed, damage, crit, pierce,
			knockback, weapon.projectile_radius, weapon.projectile_lifetime, weapon.color)
	return true
