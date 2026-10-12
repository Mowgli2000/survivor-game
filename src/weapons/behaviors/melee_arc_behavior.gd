class_name MeleeArcBehavior
extends WeaponBehavior
## Melee attack on the nearest enemy. What is drawn is what hurts (dev rule, 2026-10-10): each weapon
## has a painted swing (WeaponData.swing_fx) whose damage shape is the same shape:
## ARC (no painted sheet) a sector around the wielder, TRAVEL a wave flying forward, LINE a thin
## segment, FLURRY three fanned stabs, TARGET a circle on the enemy, RING a shockwave growing from
## it, ORBIT a blade circling the wielder. Radius = weapon area (grows with the weapon's rank); the Range stat
## lengthens the reach at 3/4 effect up to x1.6 (ADR 0029); the explosion size stat does not apply to swings.
## Rules from the playtests:
## - nothing starts inside the ring of floating weapons (RING_GAP): the hunter and his weapons stay visible;
## - the size of a circle or wave follows the weapon's cooldown (fast weapon = small discreet effect);
## - effects that land on the ground never rotate toward the enemy;
## - extra "projectiles": thrusts and waves follow one another (BURST_GAP), each toward another enemy; ground blows
##   go to different enemies too; a blade circles at an even spacing.

## Share of the Range stat bonus a melee weapon gets.
const RANGE_SHARE := 0.75
## Largest reach multiplier a melee weapon (or beam) gets from the Range stat.
const REACH_CAP := 1.6
## Nothing starts closer to the wielder than this: the ring of floating weapons plus their size.
const RING_GAP := WeaponLayout.MOUNT_RADIUS + 16.0
## An arc this wide or wider (scythe, hammer) repeats around the wielder; a narrower one (frost cone, claws) is aimed at
## another enemy each time, like a thrust.
const WIDE_ARC := 180.0
## Seconds between the repeats of an extra projectile.
const BURST_GAP := 0.1
## Size of a circle / wave hitbox: radius = HIT_BASE + HIT_PER_SECOND * cooldown, times the Area stat.
const HIT_BASE := 36.0
const HIT_PER_SECOND := 30.0
## Wedges an orbiting blade's sweep is cut into (one blow each, see _orbit).
const SWEEP_STEPS := 12
## Wave (TRAVEL): how far it flies, as a share of the reach, and its steps.
const WAVE_TRAVEL := 0.55
const WAVE_STEPS := 5
## Share of a painted effect's visible extent that actually hurts (the art glows a little beyond).
const HIT_SHARE := 0.8
## Flurry: angle between fanned stabs (rad), delay between them (s).
const FLURRY_FAN := 0.12
const FLURRY_GAP := 0.04
## Shockwave (RING): steps of its growth.
const RING_STEPS := 6
## Radius of a hit mark (WeaponData.target_sheet) on an enemy, px.
const MARK_RADIUS := 30.0


## One swing in flight: everything its delayed hits need.
class Blow extends RefCounted:
	var ctx: WeaponContext
	var data: WeaponData
	var amount: float
	var crit: bool
	var knockback: float
	var status: StatusData
	var status_chance: float
	## Enemies already hurt by this swing (a moving shape hurts each one once) and where they were.
	var skip: Dictionary = {}
	var log: Array = []


## Reach multiplier of melee weapons from the Range stat (+20 % range = +15 % reach, at most x1.6).
static func reach_multiplier(stats: StatBlock) -> float:
	return CombatMath.reach_scale(stats.get_value(StatIds.RANGE), RANGE_SHARE, REACH_CAP)


## Radius of the damage circle (or half-width of the wave) of `data`: it grows with the cooldown.
static func hit_size(data: WeaponData, reach: float) -> float:
	return (HIT_BASE + HIT_PER_SECOND * data.cooldown) * data.hit_scale * reach


func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool:
	var s := slot.stats
	var stats := ctx.stats
	var origin := ctx.owner.global_position
	var reach := reach_multiplier(stats)
	var target := ctx.pick_target(slot, origin, s.attack_range * reach)
	if target < 0:
		return false

	var spot := ctx.enemies.get_enemy(target).position
	var direction := (spot - origin).normalized()
	var radius := s.area * reach
	var half_angle := deg_to_rad(s.arc_degrees) * 0.5
	var min_dot := cos(half_angle)
	var knockback := s.knockback * stats.get_value(StatIds.KNOCKBACK)
	var count := s.projectile_count + int(stats.get_value(StatIds.PROJECTILE_COUNT))
	var data := slot.data
	var windup := WeaponVisuals.strike_delay(data.slash_style)
	var size := hit_size(data, reach)
	var used: Array[int] = []

	for i in count:
		var crit := ctx.roll_crit(s)
		var blow := Blow.new()
		blow.ctx = ctx
		blow.data = data
		blow.amount = ctx.hit_damage(s, crit)
		blow.crit = crit
		blow.knockback = knockback
		blow.status = s.status
		blow.status_chance = s.status_chance
		var fx := data.swing_fx if data.slash_sheet != null else WeaponData.SwingFx.ARC
		var dir := direction
		var where := spot
		var lag := 0.0
		var around := fx == WeaponData.SwingFx.ORBIT or (fx == WeaponData.SwingFx.ARC and s.arc_degrees >= WIDE_ARC)
		if around:
			# Extra projectiles and copies of the weapon are spread evenly around the wielder (wide swings and spins).
			dir = direction.rotated(TAU * (float(i) / count + float(slot.copy_rank) / (count * slot.copy_count)))
		else:
			match fx:
				WeaponData.SwingFx.TARGET, WeaponData.SwingFx.RING:
					# Each extra blow goes to another enemy (the nearest not yet chosen).
					var pick := target if i == 0 else ctx.enemies.find_nearest_excluding(origin, s.attack_range * reach, used)
					if pick < 0:
						pick = target
					var enemy := ctx.enemies.get_enemy(pick)
					used.append(enemy.get_instance_id())
					where = enemy.position
					dir = (where - origin).normalized()
					lag = i * BURST_GAP
					# Never on the floating weapons: pushed out of their ring.
					if where.distance_to(origin) < RING_GAP:
						where = origin + dir * RING_GAP
				_:
					# Thrusts, waves and narrow cones: one after the other, each toward another enemy (the nearest not
					# yet chosen); the same direction when there is no other one in reach.
					var pick := target if i == 0 else ctx.enemies.find_nearest_excluding(origin, s.attack_range * reach, used)
					if pick < 0:
						pick = target
					var enemy := ctx.enemies.get_enemy(pick)
					used.append(enemy.get_instance_id())
					dir = (enemy.position - origin).normalized()
					lag = i * BURST_GAP
		var delay := windup + lag
		if ctx.vfx != null:
			play_visual(ctx.vfx, data, ctx.owner, origin, dir, radius, where, delay, s.color, half_angle, size)
		match fx:
			WeaponData.SwingFx.ARC:
				_arc(blow, dir, radius, min_dot, delay)
			WeaponData.SwingFx.TRAVEL:
				_wave(blow, dir, radius, size, lag)
			WeaponData.SwingFx.LINE:
				_line(blow, dir, radius, delay)
			WeaponData.SwingFx.FLURRY:
				_flurry(blow, dir, radius, delay)
			WeaponData.SwingFx.TARGET:
				_circle(blow, where, size, delay)
			WeaponData.SwingFx.RING:
				_ring(blow, where, size, delay)
			WeaponData.SwingFx.ORBIT:
				_orbit(blow, dir, radius)
	return true


## The painted swing of `data`, placed exactly on the shape that hurts (see the shape functions below).
## `size` = radius of its damage circle / wave (hit_size). Ground effects (TARGET, RING) never rotate.
static func play_visual(vfx: Vfx, data: WeaponData, owner: Node2D, origin: Vector2, dir: Vector2, radius: float, where: Vector2,
		delay: float, color: Color, half_angle: float, size: float) -> void:
	var sheet := data.slash_sheet
	var angle := dir.angle()
	if sheet == null or data.swing_fx == WeaponData.SwingFx.ARC:
		vfx.slash(origin, angle, radius, half_angle, color, data.slash_style, owner, sheet,
			maxf(delay - WeaponVisuals.strike_delay(data.slash_style), 0.0))
		return
	match data.swing_fx:
		WeaponData.SwingFx.TRAVEL:
			vfx.sheet_travel_at(sheet, origin + dir * RING_GAP, angle, size / HIT_SHARE, radius * WAVE_TRAVEL, delay, owner)
		WeaponData.SwingFx.LINE, WeaponData.SwingFx.FLURRY:
			var length := radius * 0.5
			vfx.sheet_at(sheet, origin + dir * (RING_GAP + length), angle, length, delay, owner)
		WeaponData.SwingFx.TARGET, WeaponData.SwingFx.RING:
			vfx.sheet_at(sheet, where, 0.0, size / HIT_SHARE, delay)
		WeaponData.SwingFx.ORBIT:
			vfx.sheet_orbit_at(sheet, origin, angle - PI * 0.5, radius * 0.4, radius * 0.6, owner)


# --- shapes ---------------------------------------------------------------------------------

## Sector around the wielder (weapons without a painted swing): the code-drawn slash.
func _arc(blow: Blow, dir: Vector2, radius: float, min_dot: float, delay: float) -> void:
	_later(blow, delay, func() -> void:
		if _alive(blow):
			_hit_circle(blow, _where(blow), radius, dir, min_dot, false))


## A wave flying forward from outside the ring: a moving circle, each enemy hurt once as it passes.
func _wave(blow: Blow, dir: Vector2, radius: float, width: float, lag: float) -> void:
	var sheet := blow.data.slash_sheet
	var travel := radius * WAVE_TRAVEL
	for k in WAVE_STEPS:
		var p := (k + 0.5) / WAVE_STEPS
		_later(blow, lag + sheet.duration * p, func() -> void:
			if _alive(blow):
				_hit_circle(blow, _where(blow) + dir * (RING_GAP + travel * p), width))


## A thin line from the ring outward: everything on the segment is cut, with a mark on each.
func _line(blow: Blow, dir: Vector2, radius: float, delay: float) -> void:
	var half := blow.data.hit_width * 0.5
	_later(blow, delay, func() -> void:
		if _alive(blow):
			_hit_segment(blow, _where(blow) + dir * RING_GAP, dir * radius, half))


## Three fanned stabs one after the other, each a third of the blow.
func _flurry(blow: Blow, dir: Vector2, radius: float, delay: float) -> void:
	var half := blow.data.hit_width * 0.5
	for k in 3:
		var stab := dir.rotated((k - 1) * FLURRY_FAN)
		_later(blow, delay + k * FLURRY_GAP, func() -> void:
			if _alive(blow):
				_hit_segment(blow, _where(blow) + stab * RING_GAP, stab * radius, half, blow.amount / 3.0, false))


## A circle on the enemy: it hurts what it covers when the painted impact lands.
func _circle(blow: Blow, where: Vector2, hit_radius: float, delay: float) -> void:
	var sheet := blow.data.slash_sheet
	_later(blow, delay + sheet.duration * blow.data.hit_time, func() -> void: _hit_circle(blow, where, hit_radius))


## A shockwave growing from the enemy: each enemy is hurt when the ring reaches it.
func _ring(blow: Blow, where: Vector2, ring_radius: float, delay: float) -> void:
	var sheet := blow.data.slash_sheet
	for k in RING_STEPS:
		var p := float(k + 1) / RING_STEPS
		_later(blow, delay + sheet.duration * (blow.data.hit_time + 0.4 * p), func() -> void:
			_hit_circle(blow, where, ring_radius * (0.3 + 0.7 * p)))


## An orbiting blade: it sweeps ORBIT_SWEEP around the wielder in SWEEP_STEPS wedges, each one hurting
## what lies in it when the blade passes over (an enemy is cut when the blade reaches its angle).
func _orbit(blow: Blow, dir: Vector2, radius: float) -> void:
	var sheet := blow.data.slash_sheet
	var start := dir.angle() - PI * 0.5
	var step := Vfx.ORBIT_SWEEP / SWEEP_STEPS
	# A hair of overlap between wedges: an enemy on a boundary is never missed.
	var min_dot := cos(step * 0.5 + 0.03)
	for k in SWEEP_STEPS:
		var wedge := Vector2.from_angle(start + step * (k + 0.5))
		_later(blow, sheet.duration * (k + 0.5) / SWEEP_STEPS, func() -> void:
			if _alive(blow):
				_hit_circle(blow, _where(blow), radius * 0.95, wedge, min_dot))


# --- damage ---------------------------------------------------------------------------------

## True while the wielder is still there to strike (a pending blow dies with it).
func _alive(blow: Blow) -> bool:
	var owner := blow.ctx.owner
	return is_instance_valid(owner) and owner.is_inside_tree() and not owner.is_dead


func _where(blow: Blow) -> Vector2:
	return blow.ctx.owner.global_position


## Runs `strike` after `seconds` (now when 0).
func _later(blow: Blow, seconds: float, strike: Callable) -> void:
	var owner := blow.ctx.owner
	if seconds > 0.0 and owner.is_inside_tree():
		owner.get_tree().create_timer(seconds, false).timeout.connect(strike)
	else:
		strike.call()


## Hurts everything in a circle (a sector when `min_dot` > -1) around `center`; once per enemy per swing.
func _hit_circle(blow: Blow, center: Vector2, radius: float, dir: Vector2 = Vector2.ZERO, min_dot: float = -1.0,
		once: bool = true) -> void:
	if not _alive(blow):
		return
	var enemies := blow.ctx.enemies
	var scope := _begin(blow)
	enemies.damage_in_radius(center, radius, blow.amount, blow.crit, blow.knockback, blow.status, blow.status_chance,
		dir, min_dot, blow.skip if once else null, blow.log)
	_end(blow, scope)
	_mark(blow)


## Hurts everything on the segment [from, from + reach] (`amount` defaults to the whole blow).
func _hit_segment(blow: Blow, from: Vector2, reach: Vector2, half_width: float, amount: float = -1.0,
		once: bool = true) -> void:
	if not _alive(blow):
		return
	var enemies := blow.ctx.enemies
	var scope := _begin(blow)
	enemies.damage_along_segment(from, from + reach, half_width, blow.amount if amount < 0.0 else amount, blow.crit,
		blow.knockback, blow.status, blow.status_chance, blow.skip if once else null, blow.log)
	_end(blow, scope)
	_mark(blow)


## The holder's damage source (coop player number, items tag) is only set while it hurts.
func _begin(blow: Blow) -> Array:
	var enemies := blow.ctx.enemies
	var previous: Array = [enemies.damage_source, enemies.damage_weapon]
	enemies.damage_source = blow.ctx.source
	enemies.damage_weapon = blow.data.id
	return previous


func _end(blow: Blow, previous: Array) -> void:
	blow.ctx.enemies.damage_source = previous[0]
	blow.ctx.enemies.damage_weapon = previous[1]


## The painted mark of the weapon (an X) on every enemy just hurt: it never rotates.
func _mark(blow: Blow) -> void:
	var vfx := blow.ctx.vfx
	if vfx != null and blow.data.target_sheet != null:
		for position in blow.log:
			vfx.sheet_at(blow.data.target_sheet, position, 0.0, MARK_RADIUS, 0.0, null, true)
	blow.log.clear()
