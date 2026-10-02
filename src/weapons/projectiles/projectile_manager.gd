class_name ProjectileManager
extends Node2D
## Owns every active player projectile: movement, lifetime and hits against
## enemies through the EnemyManager spatial grid. Runs after EnemyManager.
## Rendering: one MultiMesh instance per projectile, i.e. a single draw call
## for all of them (measured: 1000 node-based projectiles cost ~2/3 of the frame).

## Visual length / width ratio of a projectile (stretched along its velocity).
const STRETCH := 1.8

var _enemies: EnemyManager
var _arena: Rect2
var _active: Array[Projectile] = []
var _pool: ObjectPool
var _candidates: Array[int] = []
var _multimesh: MultiMesh


func setup(enemies: EnemyManager, arena: Rect2, prewarm: int) -> void:
	_enemies = enemies
	_arena = arena.grow(200.0)
	_pool = ObjectPool.new(func() -> Object: return Projectile.new())
	_pool.prewarm(prewarm)


func _ready() -> void:
	process_physics_priority = 10
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_multimesh.mesh = quad
	_multimesh.instance_count = 256
	_multimesh.visible_instance_count = 0
	var renderer := MultiMeshInstance2D.new()
	renderer.multimesh = _multimesh
	renderer.texture = _make_circle_texture()
	add_child(renderer)


func spawn(pos: Vector2, velocity: Vector2, damage: float, crit: bool, pierce: int,
		knockback: float, radius: float, lifetime: float, color: Color) -> void:
	var projectile: Projectile = _pool.acquire()
	projectile.reset(pos, velocity, damage, crit, pierce, knockback, radius, lifetime, color)
	_active.append(projectile)


func active_count() -> int:
	return _active.size()


func _physics_process(delta: float) -> void:
	if _enemies == null:
		return
	var grid := _enemies.grid
	for i in range(_active.size() - 1, -1, -1):
		var p := _active[i]
		p.position += p.velocity * delta
		p.life -= delta
		var alive := p.life > 0.0 and _arena.has_point(p.position)
		if alive:
			alive = _resolve_hits(p, grid)
		if not alive:
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			_pool.release(p)
	_update_render()


## Applies damage to touched enemies. Returns false when the projectile is used up.
func _resolve_hits(p: Projectile, grid: SpatialGrid) -> bool:
	var found := grid.query_radius(p.position, p.radius + _enemies.max_radius, _candidates)
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
		_enemies.damage_enemy(index, p.damage, p.crit, p.velocity.normalized(), p.knockback)
		p.pierce_left -= 1
		if p.pierce_left < 0:
			return false
	return true


func _update_render() -> void:
	var count := _active.size()
	if count > _multimesh.instance_count:
		# Grow in steps; resizing the buffer clears it, but it is fully rewritten below.
		_multimesh.instance_count = maxi(count, _multimesh.instance_count * 2)
	_multimesh.visible_instance_count = count
	for i in count:
		var p := _active[i]
		var diameter := p.radius * 2.0
		_multimesh.set_instance_transform_2d(i,
			Transform2D(p.velocity.angle(), Vector2(diameter * STRETCH, diameter), 0.0, p.position))
		_multimesh.set_instance_color(i, p.color)


static func _make_circle_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.75, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 32
	texture.height = 32
	return texture
