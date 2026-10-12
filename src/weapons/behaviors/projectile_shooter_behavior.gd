class_name ProjectileShooterBehavior
extends WeaponBehavior
## Shoots a fan of projectiles at the nearest enemy in range (target picked from
## the owner's center, shots leave from the weapon's muzzle).
## Projectile features (pierce, bounces, explosion, status) come from the weapon stats.
## Bombs, flasks and grenades are lobbed (the alchemical cannon fires its ball straight): they fly over the enemies in an arc, spinning, and explode only
## where they land (the painted blast plays at that moment, never at launch).

const LOBBED := [
	WeaponData.ProjectileStyle.BOMB, WeaponData.ProjectileStyle.FIRE_FLASK, WeaponData.ProjectileStyle.FROST_FLASK,
	WeaponData.ProjectileStyle.GRENADE, WeaponData.ProjectileStyle.BOMB_FLASK,
]
## Peak of the arc, as a share of the throw distance (px, clamped).
const LOB_PEAK_SHARE := 0.3
const LOB_PEAK_MIN := 28.0
const LOB_PEAK_MAX := 110.0
const LOB_MIN_TIME := 0.25


## The volley goes at the thickest bunch of enemies in range (the gravity pistol: its vortex drags the bunch together)
## instead of at the nearest enemy. A bunch = the enemies within the pull / zone radius of one of them.
@export var aim_densest: bool = false
## Candidates checked for the thickest bunch (one grid query each, once per shot).
const DENSEST_CANDIDATES := 24
## Enemies looked at to find a separate landing spot for a lobbed shot.
const LOB_TRIES := 8


func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool:
	var s := slot.stats
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var range_multiplier := stats.get_value(StatIds.RANGE)
	var target := ctx.pick_target(slot, origin, s.attack_range * range_multiplier)
	if aim_densest and target >= 0:
		target = _densest_enemy(ctx, origin, s.attack_range * range_multiplier, maxf(maxf(s.pull_radius, s.explosion_radius * 0.7), 60.0), target)
	if target < 0:
		return false

	var to_target := ctx.enemies.get_enemy(target).position - (origin + slot.mount_offset)
	var base_angle := to_target.angle()

	origin = ctx.muzzle(slot, Vector2.from_angle(base_angle), to_target.length())
	var count := s.projectile_count + (int(stats.get_value(StatIds.PROJECTILE_COUNT)) if slot.data.projectile_stat_applies else 0)
	var spread := deg_to_rad(s.spread_deg)
	var inaccuracy := deg_to_rad(s.inaccuracy_deg)
	var speed := s.projectile_speed * stats.get_value(StatIds.PROJECTILE_SPEED)
	var pierce := s.pierce + int(stats.get_value(StatIds.PIERCE))
	var knockback := s.knockback * stats.get_value(StatIds.KNOCKBACK)
	var area := CombatMath.area_scale(stats.get_value(StatIds.AREA))

	# Lobbed shots (flasks, bombs, grenades) never leave in a fan, which lines them up in an arc: each lands on its own
	# spot, another enemy or bunch (see _lob_spot).
	var lobbed := s.projectile_style in LOBBED
	var target_spot := ctx.enemies.get_enemy(target).position
	var spots: Array[Vector2] = [target_spot]
	var used: Array[int] = [ctx.enemies.get_enemy(target).get_instance_id()]
	for i in count:
		var angle := base_angle + (i - (count - 1) * 0.5) * spread
		var lob_spot := target_spot
		if lobbed:
			if i > 0:
				lob_spot = _lob_spot(ctx, origin, s.attack_range * range_multiplier, s.explosion_radius * area, spots, used)
				spots.append(lob_spot)
			angle = (lob_spot - origin).angle()
		if inaccuracy > 0.0 and not lobbed:
			angle += ctx.rng.randf_range(-inaccuracy, inaccuracy)
		var crit := ctx.roll_crit(s)
		var shot := ctx.projectiles.spawn(origin, Vector2.from_angle(angle) * speed, ctx.hit_damage(s, crit), crit,
			pierce, knockback, area, s, range_multiplier)
		if s.returns and shot != null:
			shot.return_to = ctx.owner
		if aim_densest and shot != null and speed > 1.0:
			# Flies straight to the bunch and stops there (the well opens where the sphere ends).
			shot.life = maxf((ctx.enemies.get_enemy(target).position - origin).length() / speed, LOB_MIN_TIME)
		if s.projectile_style in LOBBED and shot != null and speed > 1.0:
			var distance := (lob_spot - origin).length()  # from the muzzle: it lands on its spot
			shot.lob_total = maxf(distance / speed, LOB_MIN_TIME)
			shot.life = shot.lob_total
			shot.homing = 0.0
			shot.velocity = Vector2.from_angle(angle) * distance / shot.lob_total
			shot.lob_peak = clampf(distance * LOB_PEAK_SHARE, LOB_PEAK_MIN, LOB_PEAK_MAX)
	return true


## Where the next lobbed shot of a volley lands: on the nearest enemy not yet chosen that stands at least 1.2 blast radii from
## the earlier spots; with none left, scattered around the first spot (a volley never lands in a row).
func _lob_spot(ctx: WeaponContext, origin: Vector2, reach: float, blast: float, spots: Array[Vector2], used: Array[int]) -> Vector2:
	var gap := maxf(blast * 1.2, 40.0)
	for attempt in LOB_TRIES:
		var found := ctx.enemies.find_nearest_excluding(origin, reach, used)
		if found < 0:
			break
		var enemy := ctx.enemies.get_enemy(found)
		used.append(enemy.get_instance_id())
		var clear := true
		for spot in spots:
			if enemy.position.distance_to(spot) < gap:
				clear = false
				break
		if clear:
			return enemy.position
	var around := spots[0] + Vector2.from_angle(ctx.rng.randf() * TAU) * ctx.rng.randf_range(gap, gap * 1.6)
	return origin + (around - origin).limit_length(reach)


## Index of the enemy in range with the most enemies around it (within `cluster` px); `fallback` if none beats it.
## A few candidates spread over the enemies in range, each counted with one grid query (cheap even with 650 enemies).
func _densest_enemy(ctx: WeaponContext, origin: Vector2, reach: float, cluster: float, fallback: int) -> int:
	var near: Array[int] = []
	ctx.enemies.grid.query_radius(origin, reach, near)
	var around: Array[int] = []
	var best := fallback
	var best_count := 0
	var step := maxi(1, near.size() / DENSEST_CANDIDATES)
	for a in range(0, near.size(), step):
		var candidate := ctx.enemies.get_enemy(near[a])
		if not candidate.is_alive():
			continue
		var count := ctx.enemies.grid.query_radius(candidate.position, cluster, around)
		if count > best_count:
			best_count = count
			best = near[a]
	return best
