class_name EnemyProjectileManager
extends Node2D
## Enemy shots: movement, lifetime and contact damage to any player.
## Drawn in a hot pink that player weapons never use, to stay readable.

const COLOR := Color(1.0, 0.24, 0.43)
const LIFETIME := 4.0

var _party: Party
var _arena: Rect2
var _active: Array[Projectile] = []
var _pool: ObjectPool
var _renderer: ProjectileRenderer


func setup(party: Party, arena: Rect2) -> void:
	_party = party
	_arena = arena.grow(100.0)
	_pool = ObjectPool.new(func() -> Object: return Projectile.new())


func _ready() -> void:
	process_physics_priority = 15
	_renderer = ProjectileRenderer.new(1.0, 2.2)
	add_child(_renderer)


func spawn(pos: Vector2, velocity: Vector2, damage: float, radius: float,
		style: WeaponData.ProjectileStyle = WeaponData.ProjectileStyle.ENEMY_ORB) -> void:
	var projectile: Projectile = _pool.acquire()
	projectile.reset_basic(pos, velocity, damage, radius, LIFETIME, COLOR, style)
	_active.append(projectile)


## Removes every enemy shot (end of wave).
func clear_all() -> void:
	for p in _active:
		_pool.release(p)
	_active.clear()
	_renderer.render(_active)


func active_count() -> int:
	return _active.size()


func _physics_process(delta: float) -> void:
	if _party == null:
		return
	var players := _party.members
	for i in range(_active.size() - 1, -1, -1):
		var p := _active[i]
		p.position += p.velocity * delta
		p.life -= delta
		var alive := p.life > 0.0 and _arena.has_point(p.position)
		if alive:
			for player in players:
				var reach := p.radius + player.radius
				if not player.is_dead and p.position.distance_squared_to(player.global_position) <= reach * reach:
					player.take_damage(p.damage)
					alive = false
					break
		if not alive:
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			_pool.release(p)
	_renderer.render(_active)
