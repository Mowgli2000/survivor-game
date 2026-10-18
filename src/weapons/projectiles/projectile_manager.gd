class_name ProjectileManager
extends Node2D
## Owns every active player projectile: movement, lifetime, hits (through the
## EnemyManager damage API), bounces and explosions. Runs after EnemyManager.

## Homing projectiles look for enemies within this distance.
const HOMING_RANGE := 520.0
## A boomerang comes back for at most this long (s) and is caught this close to its owner (px).
const RETURN_LIFE := 3.0
const CATCH_DISTANCE := 30.0
## Shards of an explosion (frag grenade): speed px/s, life s (about 200 px of flight), radius px, share of the shot's damage.
const FRAGMENT_SPEED := 650.0
## Burning ground: seconds between two ticks, share of the flask's damage each tick deals.
## Burning ground covers this share of the blast radius (playtest: the full radius was too big).
const ZONE_RADIUS_SHARE := 0.7
## Pierced-through blast of a shell (blast_on_pierce): share of the radius and of the damage.
const MINI_BLAST_RADIUS := 0.6
const MINI_BLAST_DAMAGE := 0.5
const ZONE_TICK := 0.5
## The painted end of a ground effect (the well collapsing) reaches this far past the zone, as a share of its radius.
const END_SHEET_REACH := 1.1
const ZONE_TICK_DAMAGE_SHARE := 0.25
## Explosive flask bounce: how far it looks for the next enemy (px), its flight time (s), share of the damage it keeps.
const REBOUND_RANGE := 330.0
const REBOUND_TIME := 0.4
const REBOUND_DAMAGE_SHARE := 0.7
const FRAGMENT_LIFETIME := 0.32
const FRAGMENT_RADIUS := 5.0
const FRAGMENT_DAMAGE_SHARE := 0.7

var _enemies: EnemyManager
var _vfx: Vfx
var _arena: Rect2
## The arena itself (shots bounce off its walls); `_arena` is the larger box where shots may still live.
var _walls: Rect2
var _active: Array[Projectile] = []
var _pool: ObjectPool
var _candidates: Array[int] = []
var _renderer: ProjectileRenderer
var _zones: Array = []
var _blades: Array[Projectile] = []


## A burning patch of ground (see _add_zone).
class _Zone extends RefCounted:
	var position := Vector2.ZERO
	var radius: float = 0.0
	var damage: float = 0.0
	var left: float = 0.0
	var next_tick: float = 0.0
	var pull_speed: float = 0.0
	var end_sheet: EffectSheet
	var status: StatusData
	var status_chance: float = 0.0
	var source: int = 0
	var weapon: StringName = &""


func setup(enemies: EnemyManager, arena: Rect2, prewarm: int, vfx: Vfx = null) -> void:
	_enemies = enemies
	_vfx = vfx
	_arena = arena.grow(200.0)
	_walls = arena
	_pool = ObjectPool.new(func() -> Object: return Projectile.new())
	_pool.prewarm(prewarm)


func _ready() -> void:
	process_physics_priority = 10
	_renderer = ProjectileRenderer.new()
	add_child(_renderer)


func spawn(pos: Vector2, velocity: Vector2, damage: float, crit: bool, pierce: int,
		knockback: float, area_multiplier: float, weapon: WeaponStats,
		range_multiplier: float = 1.0) -> Projectile:
	var projectile: Projectile = _pool.acquire()
	projectile.reset(pos, velocity, damage, crit, pierce, knockback, area_multiplier, weapon,
		range_multiplier)
	# The weapon holder that fires set the damage source just before.
	projectile.source = _enemies.damage_source if _enemies != null else 0
	projectile.weapon = _enemies.damage_weapon if _enemies != null else &""
	_active.append(projectile)
	return projectile


## Read-only: is the active projectile `index` a bomb sitting on the ground, fuse burning (tests).
func is_fused(index: int) -> bool:
	return _active[index].fused


func active_count() -> int:
	return _active.size()


## Read-only: position of the active projectile `index` (debug, tests).
func projectile_position(index: int) -> Vector2:
	return _active[index].position


func _physics_process(delta: float) -> void:
	if _enemies == null:
		return
	_tick_zones(delta)
	for i in range(_active.size() - 1, -1, -1):
		var p := _active[i]
		if p.homing > 0.0:
			_steer(p, delta)
		if p.orbit_owner != null:
			_orbit(p, delta)
		else:
			p.position += p.velocity * delta
		p.life -= delta
		if p.rehit_time > 0.0:
			p.rehit_left -= delta
			if p.rehit_left <= 0.0:
				p.rehit_left = p.rehit_time
				p.hit_ids.clear()
		if p.pull_radius > 0.0:
			_enemies.pull_in_radius(p.position, p.pull_radius, p.pull_speed, delta)
		if p.wall_bounces > 0 and not _walls.has_point(p.position):
			_bounce_off_walls(p)
		if p.coming_back:
			_fly_back(p)
		var alive := p.life > 0.0 and _arena.has_point(p.position)
		if not alive and p.returns and not p.coming_back and is_instance_valid(p.return_to):
			# A boomerang's flight is over: it turns around and may hurt each enemy again.
			p.coming_back = true
			p.hit_ids.clear()
			p.pierce_left = maxi(p.pierce_left, 1)
			p.life = RETURN_LIFE
			alive = true
		if not alive:
			if p.explosion_radius > 0.0:
				if p.fuse > 0.0 and not p.fused and _arena.has_point(p.position):
					# A bomb lands and sits there, fuse burning, before it explodes.
					p.fused = true
					p.velocity = Vector2.ZERO
					p.lob_peak = 0.0
					p.life = p.fuse
					alive = true
				else:
					# Rockets and lobbed shots that reach the end of their flight explode.
					_explode(p)
		elif p.lob_peak <= 0.0 and not p.fused and p.landing_blast:  # a lobbed shot, or a well sphere, touches nothing on the way
			alive = _resolve_hits(p)
		if not alive and p.zone_time > 0.0 and p.explosion_radius <= 0.0 and _walls.has_point(p.position):
			_add_zone(p)  # a shot with a ground effect and no blast plants it where it ends
		if not alive:
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			_pool.release(p)
	_renderer.render(_active)


## Turns a homing projectile toward the nearest enemy ahead (few projectiles
## home, so one grid query each per frame is cheap).
func _steer(p: Projectile, delta: float) -> void:
	var target := _enemies.find_nearest(p.position, HOMING_RANGE)
	if target < 0:
		return
	var wanted := (_enemies.get_enemy(target).position - p.position).angle()
	var current := p.velocity.angle()
	var turn := clampf(angle_difference(current, wanted), -p.homing * delta, p.homing * delta)
	p.velocity = p.velocity.rotated(turn)


## The blades of `slot` still turning (Shadow blades); the array is reused, read it at once.
func orbit_blades(slot: WeaponSlot) -> Array[Projectile]:
	_blades.clear()
	for p in _active:
		if p.orbit_slot == slot and p.life > 0.0:
			_blades.append(p)
	return _blades


## An orbiting blade follows its owner around (a freed owner ends it).
func _orbit(p: Projectile, delta: float) -> void:
	if not is_instance_valid(p.orbit_owner) or (p.orbit_slot != null and p.orbit_slot.retired):
		p.life = 0.0
		return
	p.orbit_angle += p.orbit_speed * delta
	var radial := Vector2.from_angle(p.orbit_angle)
	p.position = p.orbit_owner.global_position + radial * p.orbit_radius
	# Velocity = the direction of travel: the blade points along it and knocks enemies that way.
	p.velocity = radial.orthogonal() * signf(p.orbit_speed) * maxf(absf(p.orbit_speed) * p.orbit_radius, 1.0)


## Applies the projectile to touched enemies. Returns false when it is used up.
## Reflects a shot that left the arena (it comes back in, same speed).
func _bounce_off_walls(p: Projectile) -> void:
	p.wall_bounces -= 1
	if p.position.x < _walls.position.x or p.position.x > _walls.end.x:
		p.velocity.x = -p.velocity.x
	if p.position.y < _walls.position.y or p.position.y > _walls.end.y:
		p.velocity.y = -p.velocity.y
	p.position = p.position.clamp(_walls.position, _walls.end)


## A boomerang on its way back: it homes on its owner and is caught on arrival.
func _fly_back(p: Projectile) -> void:
	if not is_instance_valid(p.return_to):
		p.life = 0.0
		return
	var to_owner := p.return_to.global_position - p.position
	if to_owner.length() < CATCH_DISTANCE:
		p.life = 0.0
		return
	p.velocity = to_owner.normalized() * maxf(p.velocity.length(), 1.0)


func _resolve_hits(p: Projectile) -> bool:
	var found := _enemies.grid.query_radius(p.position, p.radius + p.half_length + _enemies.max_radius, _candidates)
	if found == 0:
		return true  # most projectiles, most ticks: nothing near
	# Damage attribution, set only when something may be hit (hot path).
	_enemies.damage_source = p.source
	_enemies.damage_weapon = p.weapon
	for k in found:
		var index := _candidates[k]
		var enemy := _enemies.get_enemy(index)
		if not enemy.is_alive():
			continue
		var reach := enemy.radius + p.radius
		var center := p.position
		if p.half_length > 0.0:  # capsule: the closest point of the blade to the enemy
			var axis := p.velocity.normalized()
			center += axis * clampf((enemy.position - p.position).dot(axis), -p.half_length, p.half_length)
		if center.distance_squared_to(enemy.position) > reach * reach:
			continue
		var id := enemy.get_instance_id()
		if p.hit_ids.has(id):
			continue
		p.hit_ids.append(id)

		if p.explosion_radius > 0.0:
			if p.blast_on_pierce and p.pierce_left > 0:
				p.pierce_left -= 1
				_mini_blast(p, enemy.position)
				continue
			_explode(p)
			return false
		var amount := p.damage
		if p.distance_damage > 0.0:
			amount *= 1.0 + p.distance_damage * clampf(p.position.distance_to(p.start) / p.range_ref, 0.0, 1.0)
		_enemies.damage_enemy(index, amount, p.crit, p.velocity.normalized(), p.knockback,
			p.status, p.status_chance)
		if _vfx != null:
			var burst := EffectSheets.impact_for(p.style)
			if burst != null:
				var star := burst == EffectSheets.STAR_IMPACT
				_vfx.sheet(burst, p.position, p.velocity.angle(),
					EffectSheets.STAR_IMPACT_SIZE if star else EffectSheets.IMPACT_SIZE,
					Color.WHITE if star else p.color.lerp(Color.WHITE, 0.35), true)
		if p.bounces_left > 0 and _bounce(p):
			return true
		p.pierce_left -= 1
		if p.pierce_left < 0:
			return false
	return true


## Redirects the projectile to the nearest enemy it has not hit yet.
func _bounce(p: Projectile) -> bool:
	var next := _enemies.find_nearest_excluding(p.position, p.bounce_range, p.hit_ids)
	if next < 0:
		return false
	p.bounces_left -= 1
	var speed := p.velocity.length()
	p.velocity = (_enemies.get_enemy(next).position - p.position).normalized() * speed
	return true


## A small blast where a piercing shell passes through an enemy.
func _mini_blast(p: Projectile, at: Vector2) -> void:
	var radius := p.explosion_radius * MINI_BLAST_RADIUS
	_enemies.damage_source = p.source
	_enemies.damage_weapon = p.weapon
	_enemies.damage_in_radius(at, radius, p.damage * MINI_BLAST_DAMAGE, p.crit, p.knockback * 0.5, p.status, p.status_chance)
	if _vfx != null:
		_vfx.explosion(at, radius, p.color, false, EffectSheets.explosion_for(p.style))
	Audio.play(Sounds.EXPLOSION_SMALL, -12.0)


func _explode(p: Projectile) -> void:
	_enemies.damage_source = p.source
	_enemies.damage_weapon = p.weapon
	if p.landing_blast:
		_enemies.damage_in_radius(p.position, p.explosion_radius, p.damage, p.crit, p.knockback,
			p.status, p.status_chance)
		if _vfx != null:
			_vfx.explosion(p.position, p.explosion_radius, p.color, true, EffectSheets.explosion_for(p.style))
		Audio.play(Sounds.EXPLOSION_BIG, -6.0)
	for k in p.fragments:
		_spawn_fragment(p, TAU * (k + 0.5) / p.fragments)
	if p.zone_time > 0.0:
		_add_zone(p)
	if p.rebounds > 0:
		_rebound(p)


## Burning ground where a flask exploded: it hurts what stands in it every ZONE_TICK seconds, and is painted as a loop.
func _add_zone(from: Projectile) -> void:
	var zone := _Zone.new()
	zone.position = from.position
	zone.radius = from.zone_radius if from.zone_radius > 0.0 else from.explosion_radius * ZONE_RADIUS_SHARE
	zone.damage = from.damage * ZONE_TICK_DAMAGE_SHARE
	zone.left = from.zone_time
	zone.pull_speed = from.pull_speed
	zone.end_sheet = from.zone_end_sheet
	zone.next_tick = ZONE_TICK
	zone.status = from.status
	zone.status_chance = from.status_chance
	zone.source = from.source
	zone.weapon = from.weapon
	_zones.append(zone)
	if _vfx != null and from.zone_sheet != null:
		_vfx.sheet_loop(from.zone_sheet, from.position, zone.radius, from.zone_time)


func _tick_zones(delta: float) -> void:
	for i in range(_zones.size() - 1, -1, -1):
		var zone: _Zone = _zones[i]
		zone.left -= delta
		zone.next_tick -= delta
		if zone.pull_speed > 0.0:
			_enemies.pull_in_radius(zone.position, zone.radius, zone.pull_speed, delta)
		if zone.next_tick <= 0.0:
			zone.next_tick += ZONE_TICK
			_enemies.damage_source = zone.source
			_enemies.damage_weapon = zone.weapon
			_enemies.damage_in_radius(zone.position, zone.radius, zone.damage, false, 0.0, zone.status, zone.status_chance)
		if zone.left <= 0.0:
			if _vfx != null and zone.end_sheet != null:
				_vfx.sheet_at(zone.end_sheet, zone.position, 0.0, zone.radius * END_SHEET_REACH)
			_zones.remove_at(i)


## An explosive flask bounces on: it flies to the nearest enemy outside the blast and explodes there too.
func _rebound(from: Projectile) -> void:
	var found := _enemies.grid.query_radius(from.position, REBOUND_RANGE, _candidates)
	var best := -1
	var best_d2 := INF
	var min_d2 := (from.explosion_radius * 0.9) * (from.explosion_radius * 0.9)
	for k in found:
		var enemy := _enemies.get_enemy(_candidates[k])
		var d2 := from.position.distance_squared_to(enemy.position)
		if enemy.is_alive() and d2 >= min_d2 and d2 < best_d2:
			best_d2 = d2
			best = _candidates[k]
	if best < 0:
		return
	var to := _enemies.get_enemy(best).position
	var flask: Projectile = _pool.acquire()
	flask.reset_basic(from.position, (to - from.position) / REBOUND_TIME, from.damage * REBOUND_DAMAGE_SHARE, from.radius,
		REBOUND_TIME, from.color, from.style)
	flask.explosion_radius = from.explosion_radius
	flask.knockback = from.knockback
	flask.status = from.status
	flask.status_chance = from.status_chance
	flask.crit = from.crit
	flask.rebounds = from.rebounds - 1
	flask.lob_total = REBOUND_TIME
	flask.lob_peak = clampf(sqrt(best_d2) * 0.4, 24.0, 90.0)
	flask.source = from.source
	flask.weapon = from.weapon
	_active.append(flask)


## One shard of an exploding shot: a short, fast, piercing bullet flying away from the blast.
func _spawn_fragment(from: Projectile, angle: float) -> void:
	var shard: Projectile = _pool.acquire()
	shard.reset_basic(from.position, Vector2.from_angle(angle) * FRAGMENT_SPEED, from.damage * FRAGMENT_DAMAGE_SHARE,
		FRAGMENT_RADIUS, FRAGMENT_LIFETIME, from.color, from.fragment_style)
	shard.pierce_left = 1
	shard.knockback = from.knockback * 0.5
	shard.source = from.source
	shard.weapon = from.weapon
	_active.append(shard)
