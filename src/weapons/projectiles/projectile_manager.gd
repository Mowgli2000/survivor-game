class_name ProjectileManager
extends Node2D
## Owns every active player projectile: movement, lifetime, hits (through the
## EnemyManager damage API), bounces and explosions. Runs after EnemyManager.

var _enemies: EnemyManager
var _vfx: Vfx
var _arena: Rect2
var _active: Array[Projectile] = []
var _pool: ObjectPool
var _candidates: Array[int] = []
var _renderer: ProjectileRenderer


func setup(enemies: EnemyManager, arena: Rect2, prewarm: int, vfx: Vfx = null) -> void:
	_enemies = enemies
	_vfx = vfx
	_arena = arena.grow(200.0)
	_pool = ObjectPool.new(func() -> Object: return Projectile.new())
	_pool.prewarm(prewarm)


func _ready() -> void:
	process_physics_priority = 10
	_renderer = ProjectileRenderer.new()
	add_child(_renderer)


func spawn(pos: Vector2, velocity: Vector2, damage: float, crit: bool, pierce: int,
		knockback: float, area_multiplier: float, weapon: WeaponStats) -> void:
	var projectile: Projectile = _pool.acquire()
	projectile.reset(pos, velocity, damage, crit, pierce, knockback, area_multiplier, weapon)
	_active.append(projectile)


func active_count() -> int:
	return _active.size()


func _physics_process(delta: float) -> void:
	if _enemies == null:
		return
	for i in range(_active.size() - 1, -1, -1):
		var p := _active[i]
		p.position += p.velocity * delta
		p.life -= delta
		var alive := p.life > 0.0 and _arena.has_point(p.position)
		if alive:
			alive = _resolve_hits(p)
		elif p.explosion_radius > 0.0:
			# Rockets that reach the end of their flight still explode.
			_explode(p)
		if not alive:
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			_pool.release(p)
	_renderer.render(_active)


## Applies the projectile to touched enemies. Returns false when it is used up.
func _resolve_hits(p: Projectile) -> bool:
	var found := _enemies.grid.query_radius(p.position, p.radius + _enemies.max_radius, _candidates)
	for k in found:
		var index := _candidates[k]
		var enemy := _enemies.get_enemy(index)
		if not enemy.is_alive():
			continue
		var reach := enemy.radius + p.radius
		if p.position.distance_squared_to(enemy.position) > reach * reach:
			continue
		var id := enemy.get_instance_id()
		if p.hit_ids.has(id):
			continue
		p.hit_ids.append(id)

		if p.explosion_radius > 0.0:
			_explode(p)
			return false
		_enemies.damage_enemy(index, p.damage, p.crit, p.velocity.normalized(), p.knockback,
			p.status, p.status_chance)
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


func _explode(p: Projectile) -> void:
	_enemies.damage_in_radius(p.position, p.explosion_radius, p.damage, p.crit, p.knockback,
		p.status, p.status_chance)
	if _vfx != null:
		_vfx.explosion(p.position, p.explosion_radius, p.color, true)
