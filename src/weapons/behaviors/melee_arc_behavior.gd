class_name MeleeArcBehavior
extends WeaponBehavior
## Slashes an arc in front of the player, toward the nearest enemy.
## Radius = weapon area, opening = arc_degrees. Extra "projectiles" add slashes
## evenly spread around the player (2 = front and back).
## The Range stat lengthens the reach at half effect, like Brotato's melee weapons
## (playtest: Range used to change nothing visible, only when the swing started).

## Share of the Range stat bonus a melee weapon gets.
const RANGE_SHARE := 0.5


## Reach multiplier of melee weapons from the Range stat (+20 % range = +10 % reach).
static func reach_multiplier(stats: StatBlock) -> float:
	return maxf(1.0 + (stats.get_value(StatIds.RANGE) - 1.0) * RANGE_SHARE, 0.1)


func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool:
	var s := slot.stats
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var reach := reach_multiplier(stats)
	var target := ctx.enemies.find_nearest(origin, s.attack_range * reach)
	if target < 0:
		return false

	var direction := (ctx.enemies.get_enemy(target).position - origin).normalized()
	var radius := s.area * stats.get_value(StatIds.AREA) * reach
	var half_angle := deg_to_rad(s.arc_degrees) * 0.5
	var min_dot := cos(half_angle)
	var knockback := s.knockback * stats.get_value(StatIds.KNOCKBACK)
	var count := s.projectile_count + int(stats.get_value(StatIds.PROJECTILE_COUNT))

	# The blow lands when the swing strikes (after its wind-up), like the slash streak: the
	# enemies it cuts through on screen are the ones it hurts (playtest 2026-10-09).
	var delay := WeaponVisuals.strike_delay(slot.data.slash_style)
	for i in count:
		var slash_dir := direction.rotated(TAU * i / count)
		var crit := ctx.roll_crit(s)
		var amount := ctx.hit_damage(s, crit)
		var strike := _strike.bind(ctx, slot.data.id, radius, amount, crit, knockback, s.status, s.status_chance, slash_dir, min_dot)
		if delay > 0.0 and ctx.owner.is_inside_tree():
			ctx.owner.get_tree().create_timer(delay, false).timeout.connect(strike)
		else:
			strike.call()
		if ctx.vfx != null:
			ctx.vfx.slash(origin, slash_dir.angle(), radius, half_angle, s.color, slot.data.slash_style, ctx.owner)
	return true


## The swing's blow, from where the player stands when it lands.
func _strike(ctx: WeaponContext, weapon_id: StringName, radius: float, amount: float, crit: bool, knockback: float,
		status: StatusData, status_chance: float, slash_dir: Vector2, min_dot: float) -> void:
	var owner := ctx.owner
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_dead:
		return
	# The holder's damage source (coop player number, items tag) is only set while it fires.
	var previous := ctx.enemies.damage_source
	var previous_weapon: StringName = ctx.enemies.damage_weapon
	ctx.enemies.damage_source = ctx.source
	ctx.enemies.damage_weapon = weapon_id
	ctx.enemies.damage_in_radius(owner.global_position, radius, amount, crit, knockback,
		status, status_chance, slash_dir, min_dot)
	ctx.enemies.damage_source = previous
	ctx.enemies.damage_weapon = previous_weapon
