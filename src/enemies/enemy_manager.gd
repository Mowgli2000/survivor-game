class_name EnemyManager
extends Node2D
## Owns every active enemy and updates them in a single loop: cleanup of the
## dead, spatial grid rebuild, statuses, movement (chase / ranged + separation
## + knockback), ranged attacks and contact damage. Runs before the other run
## systems each physics frame.
##
## It is also the single entry point to damage enemies (one target, circle,
## arc, segment), so hit rules (armor, statuses, feedback) live in one place.

signal enemy_damaged(position: Vector2, amount: float, crit: bool)
signal enemy_killed(data: EnemyData, position: Vector2, elite: bool)

const GRID_CELL_SIZE := 64.0
## Upper bound for an enemy radius (grid padding, data validation).
const MAX_ENEMY_RADIUS := 48.0
const SEPARATION_STRENGTH := 0.5
const KNOCKBACK_DECAY := 1800.0
## Ranged enemies stay within +/- this distance of their preferred range.
const RANGED_TOLERANCE := 40.0
## Strafing speed of ranged enemies, relative to their speed.
const RANGED_STRAFE := 0.6
## Ranged enemies only shoot when closer than preferred_distance x this.
const RANGED_FIRE_RANGE := 1.6
## Burn damage is shown as a number each time this much has accumulated.
const BURN_NUMBER_STEP := 2.0
const SHOCK_COLOR := Color(0.75, 0.55, 1.0)
## At most this many effects when a wave end clears every enemy at once.
const CLEAR_VFX_MAX := 40

var grid: SpatialGrid
## Largest radius among spawned enemies; pads spatial queries.
var max_radius: float = 0.0
## Size multiplier of elites (set by Run from StageData.elite_scale).
var elite_scale: float = 1.6

var _player: Player
var _arena: Rect2
var _rng: RandomNumberGenerator
var _vfx: Vfx
var _enemy_projectiles: EnemyProjectileManager
var _active: Array[Enemy] = []
var _positions := PackedVector2Array()
var _pool: ObjectPool
# Separate scratch buffers: area hits can trigger chain lightning while iterating.
var _neighbors: Array[int] = []
var _area_hits: Array[int] = []
var _chain_hits: Array[int] = []
var _chain_ids: Array[int] = []
var _query: Array[int] = []
## Physics frame of the last hit / death sound request (hundreds of hits per frame).
var _hit_sound_frame: int = -1
var _death_sound_frame: int = -1


func setup(player: Player, arena: Rect2, prewarm: int, rng: RandomNumberGenerator = null,
		vfx: Vfx = null, enemy_projectiles: EnemyProjectileManager = null) -> void:
	_player = player
	_arena = arena
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_vfx = vfx
	_enemy_projectiles = enemy_projectiles
	grid = SpatialGrid.new(arena.grow(MAX_ENEMY_RADIUS), GRID_CELL_SIZE)
	_pool = ObjectPool.new(_create_enemy)
	_pool.prewarm(prewarm)


func _ready() -> void:
	process_physics_priority = -10


func spawn(data: EnemyData, pos: Vector2, hp_multiplier: float = 1.0, elite: bool = false) -> Enemy:
	var enemy: Enemy = _pool.acquire()
	enemy.reset(data, pos, hp_multiplier, elite, elite_scale if elite else 1.0)
	enemy.animator.time = _rng.randf() * 2.0  # desync the horde's steps
	enemy.fire_timer = data.fire_cooldown * _rng.randf_range(0.5, 1.0)
	enemy.strafe_sign = 1.0 if _rng.randf() < 0.5 else -1.0
	max_radius = maxf(max_radius, enemy.radius)
	_active.append(enemy)
	return enemy


func active_count() -> int:
	return _active.size()


## True while at least one boss is alive. Linear scan: only call it on boss events.
func has_living_boss() -> bool:
	for enemy in _active:
		if enemy.data.boss and enemy.is_alive():
			return true
	return false


## Valid until the next physics frame of this manager (indices are compacted then).
func get_enemy(index: int) -> Enemy:
	return _active[index]


## Index of the nearest enemy within `max_distance`, or -1.
func find_nearest(from: Vector2, max_distance: float) -> int:
	if grid == null:
		return -1
	return grid.nearest(from, max_distance)


## Nearest living enemy within `max_distance` whose instance id is not in `exclude_ids`.
func find_nearest_excluding(from: Vector2, max_distance: float, exclude_ids: Array[int]) -> int:
	var found := grid.query_radius(from, max_distance, _query)
	var best := -1
	var best_d2 := INF
	for k in found:
		var index := _query[k]
		var enemy := _active[index]
		if not enemy.is_alive() or exclude_ids.has(enemy.get_instance_id()):
			continue
		var d2 := enemy.position.distance_squared_to(from)
		if d2 < best_d2:
			best_d2 = d2
			best = index
	return best


# --- Damage API -------------------------------------------------------------

## Hits one enemy. `status` is applied with probability `status_chance`.
func damage_enemy(index: int, amount: float, crit: bool, direction: Vector2, knockback_force: float,
		status: StatusData = null, status_chance: float = 1.0) -> void:
	var enemy := _active[index]
	if not enemy.is_alive():
		return
	var damage := CombatMath.apply_armor(amount, enemy.data.armor)
	enemy.set_flash(Enemy.FLASH_TIME)
	enemy.knockback += direction * knockback_force * enemy.data.knockback_taken
	enemy_damaged.emit(enemy.position, damage, crit)
	_lose_hp(enemy, damage)
	if status != null and _rng.randf() < status_chance:
		_apply_status(index, status, amount)


## Hits every enemy touching the circle. With `arc_min_dot` > -1, only enemies
## inside the arc of direction `arc_dir` are hit (dot product test).
## Returns the number of enemies hit.
func damage_in_radius(center: Vector2, radius: float, amount: float, crit: bool, knockback_force: float,
		status: StatusData = null, status_chance: float = 1.0,
		arc_dir: Vector2 = Vector2.ZERO, arc_min_dot: float = -1.0) -> int:
	var found := grid.query_radius(center, radius + max_radius, _area_hits)
	var hits := 0
	for k in found:
		var index := _area_hits[k]
		var enemy := _active[index]
		if not enemy.is_alive():
			continue
		var offset := enemy.position - center
		var reach := radius + enemy.radius
		var d2 := offset.length_squared()
		if d2 > reach * reach:
			continue
		var direction := offset / sqrt(d2) if d2 > 0.01 else Vector2.RIGHT
		if arc_min_dot > -1.0 and d2 > enemy.radius * enemy.radius and direction.dot(arc_dir) < arc_min_dot:
			continue
		damage_enemy(index, amount, crit, direction, knockback_force, status, status_chance)
		hits += 1
	return hits


## Hits every enemy touching the segment [from, to] widened by `half_width`.
func damage_along_segment(from: Vector2, to: Vector2, half_width: float, amount: float, crit: bool,
		knockback_force: float, status: StatusData = null, status_chance: float = 1.0) -> int:
	var found := grid.query_segment(from, to, half_width + max_radius, _area_hits)
	var direction := (to - from).normalized()
	var hits := 0
	for k in found:
		var index := _area_hits[k]
		var enemy := _active[index]
		if not enemy.is_alive():
			continue
		var reach := half_width + enemy.radius
		var closest := Geometry2D.get_closest_point_to_segment(enemy.position, from, to)
		if enemy.position.distance_squared_to(closest) > reach * reach:
			continue
		damage_enemy(index, amount, crit, direction, knockback_force, status, status_chance)
		hits += 1
	return hits


## Removes every enemy at once (end of wave): no XP, no enemy_killed.
## Effects are capped so clearing 400 enemies does not spike the frame.
func clear_all() -> void:
	var count := _active.size()
	var step := maxi(1, ceili(float(count) / CLEAR_VFX_MAX))
	for i in count:
		var enemy := _active[i]
		if _vfx != null and enemy.is_alive() and i % step == 0:
			_vfx.explosion(enemy.position, enemy.radius * 1.5, enemy.data.color, false)
		enemy.hp = 0.0
	_remove_dead()
	# The grid still holds the removed enemies' indices until the next physics
	# step; queries made before it (weapon visuals on the first frame after the
	# shop) would return out-of-range indices.
	grid.rebuild(_positions, 0)


func _lose_hp(enemy: Enemy, amount: float) -> void:
	enemy.hp -= amount
	if enemy.is_alive():
		var frame := Engine.get_physics_frames()
		if frame != _hit_sound_frame:
			_hit_sound_frame = frame
			Audio.play(Sounds.ENEMY_HIT, -10.0)
		return
	enemy.visible = false
	if _vfx != null:
		_vfx.explosion(enemy.position, enemy.radius * 1.8, enemy.data.color, false)
	if enemy.elite or enemy.data.boss:
		Audio.play(Sounds.ELITE_DEATH, -2.0)
	else:
		var frame := Engine.get_physics_frames()
		if frame != _death_sound_frame:
			_death_sound_frame = frame
			Audio.play(Sounds.ENEMY_DEATH, -8.0)
	enemy_killed.emit(enemy.data, enemy.position, enemy.elite)


func _apply_status(index: int, status: StatusData, hit_damage: float) -> void:
	var enemy := _active[index]
	match status.type:
		StatusData.Type.BURN:
			if enemy.is_alive():
				enemy.apply_burn(hit_damage * status.power, status.duration)
		StatusData.Type.SLOW:
			if enemy.is_alive():
				enemy.apply_slow(status.power, status.duration)
		StatusData.Type.SHOCK:
			_chain_lightning(index, hit_damage * status.power, status.chain_count, status.chain_range)


## Lightning jumps from enemy to enemy, never hitting the same one twice.
func _chain_lightning(start: int, damage: float, count: int, chain_range: float) -> void:
	_chain_ids.clear()
	_chain_ids.append(_active[start].get_instance_id())
	var from := _active[start].position
	for n in count:
		var found := grid.query_radius(from, chain_range, _chain_hits)
		var best := -1
		var best_d2 := INF
		for k in found:
			var index := _chain_hits[k]
			var enemy := _active[index]
			if not enemy.is_alive() or _chain_ids.has(enemy.get_instance_id()):
				continue
			var d2 := enemy.position.distance_squared_to(from)
			if d2 < best_d2:
				best_d2 = d2
				best = index
		if best < 0:
			return
		var to := _active[best].position
		_chain_ids.append(_active[best].get_instance_id())
		if _vfx != null:
			_vfx.lightning(from, to, SHOCK_COLOR)
		damage_enemy(best, damage, false, (to - from).normalized(), 0.0)
		from = to


# --- Update loop ------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _player == null:
		return
	_remove_dead()
	var count := _active.size()
	if _positions.size() < count:
		_positions.resize(count)
	for i in count:
		_positions[i] = _active[i].position
	grid.rebuild(_positions, count)

	var player_pos := _player.global_position
	var player_radius := _player.radius
	for i in count:
		var enemy := _active[i]
		if not enemy.is_alive():
			continue
		if enemy.burn_time > 0.0:
			_tick_burn(enemy, delta)
			if not enemy.is_alive():
				continue
		var speed := enemy.data.speed
		if enemy.slow_time > 0.0:
			speed *= 1.0 - enemy.slow_factor
			enemy.slow_time -= delta
			if enemy.slow_time <= 0.0:
				enemy.end_slow()

		var pos := enemy.position
		var to_player := player_pos - pos
		var distance := to_player.length()
		var direction := to_player / distance if distance > 0.001 else Vector2.RIGHT
		var velocity: Vector2
		if enemy.data.movement == EnemyData.Movement.RANGED:
			velocity = _ranged_velocity(enemy, direction, distance, speed, delta)
		else:
			velocity = direction * speed

		# Separation: push away from overlapping neighbours.
		var push := Vector2.ZERO
		var found := grid.query_radius(pos, enemy.radius + max_radius, _neighbors)
		for k in found:
			var j := _neighbors[k]
			if j == i:
				continue
			var other := _active[j]
			var offset := pos - other.position
			var min_dist := enemy.radius + other.radius
			var d2 := offset.length_squared()
			if d2 < min_dist * min_dist and d2 > 0.0001:
				var d := sqrt(d2)
				push += offset / d * (min_dist - d)
		pos += velocity * delta + push * SEPARATION_STRENGTH + enemy.knockback * delta
		enemy.knockback = enemy.knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		enemy.position = pos.clamp(_arena.position, _arena.end)
		if enemy.animator.sheet != null:
			var anim := &"walk" if velocity.length_squared() > 4.0 else &"idle"
			if enemy.animator.advance(delta, anim, direction.x):
				enemy.queue_redraw()
		elif enemy.data.shape_sides >= 3:
			enemy.rotation = direction.angle()

		if enemy.flash > 0.0:
			enemy.set_flash(maxf(enemy.flash - delta, 0.0))

		var touch := enemy.radius + player_radius
		if distance <= touch:
			_player.take_damage(enemy.data.contact_damage)


## Approach until preferred_distance, back off when too close, strafe in between; shoot.
func _ranged_velocity(enemy: Enemy, direction: Vector2, distance: float, speed: float, delta: float) -> Vector2:
	var data := enemy.data
	var velocity: Vector2
	if distance > data.preferred_distance + RANGED_TOLERANCE:
		velocity = direction * speed
	elif distance < data.preferred_distance - RANGED_TOLERANCE:
		velocity = -direction * speed
	else:
		velocity = direction.orthogonal() * enemy.strafe_sign * speed * RANGED_STRAFE
	enemy.fire_timer -= delta
	if enemy.fire_timer <= 0.0 and distance <= data.preferred_distance * RANGED_FIRE_RANGE:
		enemy.fire_timer = data.fire_cooldown
		if _enemy_projectiles != null:
			_enemy_projectiles.spawn(enemy.position, direction * data.projectile_speed,
				data.projectile_damage, data.projectile_radius)
	return velocity


func _tick_burn(enemy: Enemy, delta: float) -> void:
	var step := minf(delta, enemy.burn_time)
	var damage := enemy.burn_dps * step
	enemy.burn_time -= delta
	enemy.burn_pending += damage
	if enemy.burn_pending >= BURN_NUMBER_STEP or enemy.burn_time <= 0.0:
		enemy_damaged.emit(enemy.position, enemy.burn_pending, false)
		enemy.burn_pending = 0.0
	if enemy.burn_time <= 0.0:
		enemy.end_burn()
	_lose_hp(enemy, damage)


func _remove_dead() -> void:
	for i in range(_active.size() - 1, -1, -1):
		var enemy := _active[i]
		if enemy.is_alive():
			continue
		enemy.visible = false
		_active[i] = _active[_active.size() - 1]
		_active.pop_back()
		_pool.release(enemy)


func _create_enemy() -> Enemy:
	var enemy := Enemy.new()
	enemy.visible = false
	add_child(enemy)
	return enemy
