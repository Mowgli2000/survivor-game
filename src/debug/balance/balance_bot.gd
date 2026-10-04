class_name BalanceBot
extends RefCounted
## Movement of the balance simulator's player (ADR 0019): a "decent player". It
## fights at its weapons' range and circles its target, side-steps enemy shots,
## flees when surrounded or low on HP, and keeps away from the walls. Weapons aim
## by themselves.

const ENEMY_RADIUS := 260.0
const SHOT_RADIUS := 170.0
const WALL_MARGIN := 260.0
## Sideways share of the escape direction: circling keeps kills flowing.
const ORBIT := 0.55
const CENTER_PULL := 0.15
## Surrounded (this many enemies this close) or below this HP share: flee.
const CROWD_RADIUS := 110.0
const CROWD_LIMIT := 6
const FLEE_HP := 0.35

var _run: Run
var _hits: Array[int] = []
var _orbit_sign: float = 1.0


func setup(run: Run) -> void:
	_run = run


## Direction for this physics tick (length <= 1). Fights at its weapons' range:
## closes in when the nearest enemy is beyond it, backs off when closer, circles
## in between; flees (dodging shots) when surrounded or low on HP.
func steer() -> Vector2:
	if _run == null or _run.player == null:
		return Vector2.ZERO
	var me := _run.player.global_position
	var push := Vector2.ZERO
	var nearest := Vector2.INF
	var nearest_d := INF
	var crowd := 0
	var enemies := _run.enemies
	if enemies != null and enemies.grid != null:
		var count := enemies.grid.query_radius(me, ENEMY_RADIUS, _hits)
		for k in count:
			var enemy := enemies.get_enemy(_hits[k])
			if enemy == null:
				continue
			var away := me - enemy.position
			var d := maxf(away.length(), 8.0)
			if d < nearest_d:
				nearest_d = d
				nearest = enemy.position
			if d < CROWD_RADIUS:
				crowd += 1
			var weight := 3.0 if enemy.data.boss else 1.0
			push += away / d * weight * (ENEMY_RADIUS / d) * (ENEMY_RADIUS / d)
		if nearest_d == INF:
			var target := enemies.find_nearest(me, 2000.0)
			if target >= 0:
				nearest = enemies.get_enemy(target).position
				nearest_d = me.distance_to(nearest)
	var dodge := Vector2.ZERO
	if _run.enemy_projectiles != null:
		for shot in _run.enemy_projectiles.active_projectiles():
			var away := me - shot.position
			var d := away.length()
			if d < SHOT_RADIUS and d > 1.0 and shot.velocity.dot(away) > 0.0:
				# Step sideways out of the shot's path rather than straight back.
				var side := shot.velocity.orthogonal().normalized()
				if side.dot(away) < 0.0:
					side = -side
				dodge += side * (SHOT_RADIUS / d)
	var rect := _arena_rect()
	var wall := Vector2.ZERO
	wall.x += _wall_push(me.x - rect.position.x) - _wall_push(rect.end.x - me.x)
	wall.y += _wall_push(me.y - rect.position.y) - _wall_push(rect.end.y - me.y)
	var to_center := (rect.get_center() - me) / maxf(rect.size.x, 1.0)
	if nearest_d == INF:
		return (to_center * 4.0 + wall).limit_length(1.0)
	var hp_ratio := _run.player.hp / maxf(_run.player.stats.get_value(StatIds.MAX_HP), 1.0)
	var to_enemy := (nearest - me) / maxf(nearest_d, 1.0)
	var orbit := to_enemy.orthogonal() * _orbit_sign
	if wall.dot(orbit) < -0.5:
		_orbit_sign = -_orbit_sign
		orbit = -orbit
	var direction: Vector2
	if crowd >= CROWD_LIMIT or hp_ratio < FLEE_HP:
		direction = push.normalized() * (1.0 - ORBIT) + orbit * ORBIT
	else:
		var engage := _engage_distance()
		var radial := clampf((nearest_d - engage) / engage, -1.0, 1.0)
		direction = to_enemy * radial + orbit * (1.0 - absf(radial) * 0.5)
	direction += dodge * 1.5 + wall * 1.5 + to_center * CENTER_PULL
	return direction.normalized() if direction.length_squared() > 0.0001 else Vector2.ZERO


## Distance to keep from the nearest enemy: a share of the shortest weapon reach.
func _engage_distance() -> float:
	var reach := INF
	var stats := _run.player.stats
	for slot in _run.player.weapons.get_slots():
		var r := slot.stats.attack_range * stats.get_value(StatIds.RANGE)
		if slot.data.is_melee():
			r = minf(r, slot.stats.area * stats.get_value(StatIds.AREA))
		reach = minf(reach, r)
	return clampf(reach * 0.6, 70.0, 380.0) if reach < INF else 200.0


func _arena_rect() -> Rect2:
	var size := _run.config.arena_size
	return Rect2(-size * 0.5, size)


## Push away from a wall `distance` px away (0 beyond WALL_MARGIN).
static func _wall_push(distance: float) -> float:
	return 0.0 if distance >= WALL_MARGIN else 1.0 - maxf(distance, 0.0) / WALL_MARGIN
