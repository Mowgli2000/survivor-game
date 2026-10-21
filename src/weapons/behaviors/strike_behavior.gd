class_name StrikeBehavior
extends WeaponBehavior
## Strike from the sky (meteors): each "projectile" falls on an enemy picked around a random spot in
## range (not always the nearest one). The painted rock falls first; it hurts everything within the
## weapon's area when it lands (what is drawn is what hurts), then the impact is painted.
## Counts as a ranged weapon (WeaponData.is_melee).

## Where the rock starts, relative to the impact point: straight above, out of the top of the screen (it comes from the sky).
const FALL_FROM := Vector2(0.0, -720.0)
## Side of the rock's frame, as a multiple of the damage radius.
const ROCK_SIDE_PER_RADIUS := 2.2
## Seconds between the meteors of one volley (dev, 2026-10-11: they must not come down together).
const BURST_GAP := 0.25
## Meteors of one volley land at least this many damage radii apart (they spread over the map, each on another bunch).
const SPREAD_RADII := 1.6
## Spots tried for a meteor to find one far enough from the previous ones.
const SPREAD_TRIES := 8
## Fall time without a painted rock (drawn streak), seconds.
const FALL_TIME := 0.35
## Opacity of the rock and the impact while a boss is alive: they must not hide it (dev playtest, 2026-10-21).
const BOSS_FADE := 0.35

## Painted rock (EffectSheet, Vfx.sheet_fall); null: a streak drawn by code.
@export var fall_sheet: EffectSheet
## Painted impact (fitted to the damage radius); null: the fire explosion.
@export var impact_sheet: EffectSheet


func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool:
	var s := slot.stats
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var reach := s.attack_range * stats.get_value(StatIds.RANGE)
	if ctx.enemies.find_nearest(origin, reach) < 0:
		return false
	var radius := s.area * CombatMath.area_scale(stats.get_value(StatIds.AREA))
	var knockback := s.knockback * stats.get_value(StatIds.KNOCKBACK)
	var count := s.projectile_count + int(stats.get_value(StatIds.PROJECTILE_COUNT))
	var fall := fall_sheet.duration if fall_sheet != null else FALL_TIME
	var tint := Color(1, 1, 1, BOSS_FADE) if ctx.enemies.has_living_phased() else Color.WHITE
	var landed: Array[Vector2] = []
	for i in count:
		var target := _pick_spread_target(ctx, origin, reach, landed, radius * SPREAD_RADII)
		if target < 0:
			continue
		var point := ctx.enemies.get_enemy(target).position
		landed.append(point)
		var crit := ctx.roll_crit(s)
		var amount := ctx.hit_damage(s, crit)
		var lag := i * BURST_GAP
		if ctx.vfx != null:
			if fall_sheet != null:
				ctx.vfx.sheet_fall(fall_sheet, point, (-FALL_FROM).angle(), radius * ROCK_SIDE_PER_RADIUS,
					FALL_FROM.length(), lag, tint)
			else:
				ctx.vfx.beam(point + FALL_FROM, point, radius * 0.35, s.color)
		var land := func() -> void:
			if not is_instance_valid(ctx.owner) or not ctx.owner.is_inside_tree():
				return
			_land(slot.data, ctx, point, radius, amount, crit, knockback, s, tint)
		var seconds := lag + fall
		if seconds > 0.0 and ctx.owner.is_inside_tree():
			ctx.owner.get_tree().create_timer(seconds, false).timeout.connect(land)
		else:
			land.call()
	return true


## The rock lands: everything in the radius is hurt, the impact is painted.
func _land(data: WeaponData, ctx: WeaponContext, point: Vector2, radius: float, amount: float, crit: bool,
		knockback: float, s: WeaponStats, tint: Color = Color.WHITE) -> void:
	var enemies := ctx.enemies
	var previous: Array = [enemies.damage_source, enemies.damage_weapon]
	enemies.damage_source = ctx.source
	enemies.damage_weapon = data.id
	enemies.damage_in_radius(point, radius, amount, crit, knockback, s.status, s.status_chance)
	enemies.damage_source = previous[0]
	enemies.damage_weapon = previous[1]
	if ctx.vfx != null:
		ctx.vfx.explosion(point, radius, s.color, false, impact_sheet if impact_sheet != null else EffectSheets.EXPLOSION_FIRE, tint)


## A target for the next meteor: picks random spots until one is `gap` px from every earlier impact; if none is,
## the farthest from them (a meteor is never lost, but it avoids the others as much as it can).
func _pick_spread_target(ctx: WeaponContext, origin: Vector2, reach: float, landed: Array[Vector2], gap: float) -> int:
	var best := -1
	var best_gap := -1.0
	for attempt in SPREAD_TRIES:
		var target := _pick_target(ctx, origin, reach)
		if target < 0:
			break
		var spot := ctx.enemies.get_enemy(target).position
		var nearest := INF
		for other in landed:
			nearest = minf(nearest, spot.distance_to(other))
		if nearest >= gap:
			return target
		if nearest > best_gap:
			best_gap = nearest
			best = target
	return best


## Enemy nearest to a random spot within reach (falls back to the nearest one).
func _pick_target(ctx: WeaponContext, origin: Vector2, reach: float) -> int:
	if ctx.rng != null:
		var probe := origin + Vector2.from_angle(ctx.rng.randf() * TAU) * ctx.rng.randf_range(0.0, reach * 0.7)
		var target := ctx.enemies.find_nearest(probe, reach * 0.5)
		if target >= 0 and ctx.enemies.get_enemy(target).position.distance_to(origin) <= reach:
			return target
	return ctx.enemies.find_nearest(origin, reach)
