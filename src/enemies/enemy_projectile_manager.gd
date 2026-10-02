class_name EnemyProjectileManager
extends Node2D
## Enemy shots: movement, lifetime and contact damage to the player.
## Drawn in a hot pink that player weapons never use, to stay readable.

const COLOR := Color(1.0, 0.2, 0.45)
const LIFETIME := 4.0

var _player: Player
var _arena: Rect2
var _active: Array[Projectile] = []
var _pool: ObjectPool
var _renderer: ProjectileRenderer


func setup(player: Player, arena: Rect2) -> void:
	_player = player
	_arena = arena.grow(100.0)
	_pool = ObjectPool.new(func() -> Object: return Projectile.new())


func _ready() -> void:
	process_physics_priority = 15
	_renderer = ProjectileRenderer.new(1.0, 2.2)
	add_child(_renderer)


func spawn(pos: Vector2, velocity: Vector2, damage: float, radius: float) -> void:
	var projectile: Projectile = _pool.acquire()
	projectile.reset_basic(pos, velocity, damage, radius, LIFETIME, COLOR)
	_active.append(projectile)


func active_count() -> int:
	return _active.size()


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var player_pos := _player.global_position
	for i in range(_active.size() - 1, -1, -1):
		var p := _active[i]
		p.position += p.velocity * delta
		p.life -= delta
		var alive := p.life > 0.0 and _arena.has_point(p.position)
		var reach := p.radius + _player.radius
		if alive and not _player.is_dead and p.position.distance_squared_to(player_pos) <= reach * reach:
			_player.take_damage(p.damage)
			alive = false
		if not alive:
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			_pool.release(p)
	_renderer.render(_active)
