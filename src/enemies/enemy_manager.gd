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
## An enemy with boss phases appeared (BossDirector takes it from here).
signal boss_spawned(enemy: Enemy)

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
## Spawner enemies never push the count above this (Run sets StageData.max_enemies).
var spawn_cap: int = 100000
## Player number of whoever deals the current damage (ADR 0017): set by the
## attacker before calling the damage API, read by kill / hit listeners.
var damage_source: int = 0
## What deals the current damage, for the end-of-run summary: a weapon id,
## ITEMS_TAG or BURN_TAG. Set with damage_source by the attacker.
var damage_weapon: StringName = &""

## Damage actually dealt (HP removed) per player, per damage_weapon.
var _dealt: Array[Dictionary] = []
## Biggest single hit per player.
var _best_hit := PackedFloat32Array()

var _party: Party
var _arena: Rect2
var _rng: RandomNumberGenerator
var _vfx: Vfx
var _enemy_projectiles: EnemyProjectileManager
var _active: Array[Enemy] = []
var _positions := PackedVector2Array()
## Radii matching _positions: separation reads packed arrays, not Enemy nodes.
var _radii := PackedFloat32Array()
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


func setup(party: Party, arena: Rect2, prewarm: int, rng: RandomNumberGenerator = null,
		vfx: Vfx = null, enemy_projectiles: EnemyProjectileManager = null) -> void:
	_party = party
	_arena = arena
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_vfx = vfx
	_enemy_projectiles = enemy_projectiles
	grid = SpatialGrid.new(arena.grow(MAX_ENEMY_RADIUS), GRID_CELL_SIZE)
	_pool = ObjectPool.new(_create_enemy)
	_pool.prewarm(prewarm)


func _ready() -> void:
	process_physics_priority = -10


func spawn(data: EnemyData, pos: Vector2, hp_multiplier: float = 1.0, elite: bool = false,
		damage_multiplier: float = 1.0) -> Enemy:
	var enemy: Enemy = _pool.acquire()
	enemy.reset(data, pos, hp_multiplier, elite, elite_scale if elite else 1.0)
	enemy.damage_multiplier = damage_multiplier
	enemy.animator.time = _rng.randf() * 2.0  # desync the horde's steps
	enemy.fire_timer = data.fire_cooldown * _rng.randf_range(0.5, 1.0)
	enemy.strafe_sign = 1.0 if _rng.randf() < 0.5 else -1.0
	max_radius = maxf(max_radius, enemy.radius)
	_active.append(enemy)
	# Regular monsters spawn off screen: only the boss entrance gets its gate.
	if _vfx != null and data.boss:
		_vfx.portal(pos, enemy.radius * 1.6, true)
	if not data.phases.is_empty():
		boss_spawned.emit(enemy)
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
const ITEMS_TAG := &"items"
const BURN_TAG := &"burn"


## Damage dealt by player `source`, by weapon id / ITEMS_TAG / BURN_TAG.
func damage_dealt(source: int) -> Dictionary:
	return _dealt[source] if source >= 0 and source < _dealt.size() else {}


func best_hit(source: int) -> float:
	return _best_hit[source] if source >= 0 and source < _best_hit.size() else 0.0


func _record_damage(amount: float) -> void:
	var source := maxi(damage_source, 0)
	while _dealt.size() <= source:
		_dealt.append({})
		_best_hit.append(0.0)
	_dealt[source][damage_weapon] = _dealt[source].get(damage_weapon, 0.0) + amount
	if damage_weapon != BURN_TAG:
		_best_hit[source] = maxf(_best_hit[source], amount)


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
## Most enemies one area hit (slash, explosion, strike) can damage; 0 = all.
## Balance experiment (session 8): dense late crowds made area weapons trivialize.
var area_max_targets: int = 20
## Per player (damage_source): the cap grows with the Zone stat (D66), so Zone
## keeps its value in dense crowds. Missing entries count as 1.0.
var area_target_scale: PackedFloat32Array = PackedFloat32Array()


## Most enemies one area hit of player `source` can damage (0 = all).
func area_targets_for(source: int) -> int:
	if area_max_targets <= 0:
		return 0
	var scale := area_target_scale[source] if source >= 0 and source < area_target_scale.size() else 1.0
	return ceili(area_max_targets * maxf(scale, 1.0) - 0.0001)


func set_area_target_scale(source: int, scale: float) -> void:
	if source < 0:
		return
	if area_target_scale.size() <= source:
		var old := area_target_scale.size()
		area_target_scale.resize(source + 1)
		for i in range(old, source + 1):
			area_target_scale[i] = 1.0
	area_target_scale[source] = scale


func damage_in_radius(center: Vector2, radius: float, amount: float, crit: bool, knockback_force: float,
		status: StatusData = null, status_chance: float = 1.0,
		arc_dir: Vector2 = Vector2.ZERO, arc_min_dot: float = -1.0) -> int:
	var found := grid.query_radius(center, radius + max_radius, _area_hits)
	var max_targets := area_targets_for(damage_source)
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
		if area_max_targets > 0 and hits >= max_targets:
			break
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
	_record_damage(minf(amount, maxf(enemy.hp, 0.0)))
	enemy.hp -= amount
	if enemy.is_alive():
		var frame := Engine.get_physics_frames()
		if frame != _hit_sound_frame:
			_hit_sound_frame = frame
			Audio.play(Sounds.ENEMY_HIT, -10.0)
		return
	enemy.visible = false
	if _vfx != null:
		_vfx.death(enemy.position, enemy.radius * 1.4, enemy.data.color)
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
				enemy.burn_source = damage_source
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
	if _party == null:
		return
	_remove_dead()
	var count := _active.size()
	if _positions.size() < count:
		_positions.resize(count)
		_radii.resize(count)
	for i in count:
		var other := _active[i]
		_positions[i] = other.position
		_radii[i] = other.radius
	grid.rebuild(_positions, count)

	# Solo: one target for everyone. Coop: each enemy chases the nearest living
	# player (two players compared inline: no call per enemy).
	var solo_target: Player = _party.members[0] if _party.size() == 1 else null
	var first: Player = _party.members[0]
	var second: Player = _party.members[1] if _party.size() > 1 else null
	if second != null and (first.is_dead or second.is_dead):
		solo_target = second if first.is_dead else first
		if first.is_dead and second.is_dead:
			solo_target = null
	var first_pos := first.global_position
	var second_pos := second.global_position if second != null else first_pos
	var fallback_pos := _party.center()
	var tick_parity := Engine.get_physics_frames() & 1
	for i in count:
		var enemy := _active[i]
		if not enemy.is_alive():
			continue
		if enemy.burn_time > 0.0:
			_tick_burn(enemy, delta)
			if not enemy.is_alive():
				continue
		var speed := enemy.data.speed * enemy.speed_multiplier
		if enemy.slow_time > 0.0:
			speed *= 1.0 - enemy.slow_factor
			enemy.slow_time -= delta
			if enemy.slow_time <= 0.0:
				enemy.end_slow()

		var pos := enemy.position
		var target := solo_target
		if target == null and second != null and not first.is_dead:
			target = first if pos.distance_squared_to(first_pos) <= pos.distance_squared_to(second_pos) else second
		var player_pos := target.global_position if target != null else fallback_pos
		var to_player := player_pos - pos
		var distance := to_player.length()
		var direction := to_player / distance if distance > 0.001 else Vector2.RIGHT
		match enemy.data.movement:
			EnemyData.Movement.CHARGER:
				_update_charger(enemy, direction, distance, delta)
			EnemyData.Movement.KAMIKAZE:
				if _update_kamikaze(enemy, distance, delta):
					continue
			EnemyData.Movement.SPAWNER:
				_update_spawner(enemy, delta)
		var velocity: Vector2
		if enemy.forced_time > 0.0:
			enemy.forced_time -= delta
			velocity = enemy.forced_velocity
		elif enemy.data.movement == EnemyData.Movement.RANGED:
			velocity = _ranged_velocity(enemy, direction, distance, speed, delta)
		else:
			velocity = direction * speed

		# Separation: push away from overlapping neighbours. Half of the enemies
		# recompute it each tick (alternating), the others reuse their last push:
		# the most expensive part of the loop with 600+ packed enemies.
		if (i + tick_parity) & 1 == 0:
			var push := Vector2.ZERO
			var radius := enemy.radius
			var found := grid.query_radius(pos, radius + max_radius, _neighbors)
			for k in found:
				var j := _neighbors[k]
				if j == i:
					continue
				var offset := pos - _positions[j]
				var min_dist := radius + _radii[j]
				var d2 := offset.length_squared()
				if d2 < min_dist * min_dist and d2 > 0.0001:
					var d := sqrt(d2)
					push += offset / d * (min_dist - d)
			enemy.separation = push
		pos += velocity * delta + enemy.separation * SEPARATION_STRENGTH + enemy.knockback * delta
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

		if target != null and distance <= enemy.radius + target.radius:
			target.take_damage(enemy.data.contact_damage * enemy.damage_multiplier)


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
				data.projectile_damage * enemy.damage_multiplier, data.projectile_radius, data.projectile_style)
	return velocity


## Telegraph (stand still, warning line) once in range, then a straight rush.
func _update_charger(enemy: Enemy, direction: Vector2, distance: float, delta: float) -> void:
	var data := enemy.data
	enemy.special_timer -= delta
	if enemy.special_state == 1:
		if enemy.special_timer <= 0.0:
			enemy.special_state = 0
			enemy.forced_velocity = enemy.special_dir * data.charge_speed
			enemy.forced_time = data.charge_duration
			enemy.special_timer = data.charge_duration + data.charge_cooldown
	elif enemy.special_timer <= 0.0 and distance <= data.charge_range:
		enemy.special_state = 1
		enemy.special_dir = direction
		enemy.special_timer = data.charge_windup
		enemy.forced_velocity = Vector2.ZERO
		enemy.forced_time = data.charge_windup
		if _vfx != null:
			var end := enemy.position + direction * data.charge_speed * data.charge_duration
			_vfx.warning_line(enemy.position, end, enemy.radius * 1.6, data.color, data.charge_windup)


## Fuse once close, then explode. Returns true when it blew up (self-destruct:
## removed without enemy_killed, so no XP; killing it first is the reward).
func _update_kamikaze(enemy: Enemy, distance: float, delta: float) -> bool:
	var data := enemy.data
	if enemy.special_state == 0:
		if distance <= data.fuse_range:
			enemy.special_state = 1
			enemy.special_timer = data.fuse_time
			enemy.forced_velocity = Vector2.ZERO
			enemy.forced_time = data.fuse_time + 1.0
			if _vfx != null:
				_vfx.warning_circle(enemy.position, data.blast_radius, data.color, data.fuse_time)
		return false
	enemy.special_timer -= delta
	if enemy.special_timer > 0.0:
		return false
	if _vfx != null:
		_vfx.explosion(enemy.position, data.blast_radius, data.color, true)
	Audio.play(Sounds.EXPLOSION, -6.0)
	for player in _party.members:
		var reach := data.blast_radius + player.radius
		if enemy.position.distance_squared_to(player.global_position) <= reach * reach:
			player.take_damage(data.blast_damage * enemy.damage_multiplier)
	enemy.hp = 0.0
	enemy.visible = false
	return true


## Every spawn_cooldown seconds, minions in a ring with the spawner's own HP
## and damage scaling, if the whole group fits under spawn_cap.
func _update_spawner(enemy: Enemy, delta: float) -> void:
	var data := enemy.data
	enemy.special_timer -= delta
	if enemy.special_timer > 0.0 or data.spawn_enemy == null:
		return
	enemy.special_timer = data.spawn_cooldown
	if _active.size() + data.spawn_count > spawn_cap:
		return
	var hp_multiplier := enemy.max_hp / data.max_hp
	for k in data.spawn_count:
		var pos := enemy.position + Vector2.from_angle(TAU * k / data.spawn_count) * (enemy.radius + 30.0)
		spawn(data.spawn_enemy, pos, hp_multiplier, false, enemy.damage_multiplier)


func _tick_burn(enemy: Enemy, delta: float) -> void:
	damage_source = enemy.burn_source
	damage_weapon = BURN_TAG
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
