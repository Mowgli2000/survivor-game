class_name EnemyManager
extends Node2D
## Owns every active enemy and updates them in a single loop: cleanup of the
## dead, spatial grid rebuild, movement (chase + separation + knockback) and
## contact damage. Runs before the other run systems each physics frame.

signal enemy_damaged(position: Vector2, amount: float, crit: bool)
signal enemy_killed(data: EnemyData, position: Vector2)

const GRID_CELL_SIZE := 64.0
## Upper bound for an enemy radius (grid padding, data validation).
const MAX_ENEMY_RADIUS := 48.0
const SEPARATION_STRENGTH := 0.5
const KNOCKBACK_DECAY := 1800.0

var grid: SpatialGrid
## Largest radius among spawned enemies; pads spatial queries.
var max_radius: float = 0.0

var _player: Player
var _arena: Rect2
var _active: Array[Enemy] = []
var _positions := PackedVector2Array()
var _pool: ObjectPool
var _neighbors: Array[int] = []


func setup(player: Player, arena: Rect2, prewarm: int) -> void:
	_player = player
	_arena = arena
	grid = SpatialGrid.new(arena.grow(MAX_ENEMY_RADIUS), GRID_CELL_SIZE)
	_pool = ObjectPool.new(_create_enemy)
	_pool.prewarm(prewarm)


func _ready() -> void:
	process_physics_priority = -10


func spawn(data: EnemyData, pos: Vector2, hp_multiplier: float = 1.0) -> Enemy:
	var enemy: Enemy = _pool.acquire()
	enemy.reset(data, pos, hp_multiplier)
	max_radius = maxf(max_radius, enemy.radius)
	_active.append(enemy)
	return enemy


func active_count() -> int:
	return _active.size()


## Valid until the next physics frame of this manager (indices are compacted then).
func get_enemy(index: int) -> Enemy:
	return _active[index]


## Index of the nearest enemy within `max_distance`, or -1.
func find_nearest(from: Vector2, max_distance: float) -> int:
	if grid == null:
		return -1
	return grid.nearest(from, max_distance)


func damage_enemy(index: int, amount: float, crit: bool, direction: Vector2, knockback_force: float) -> void:
	var enemy := _active[index]
	if not enemy.is_alive():
		return
	var damage := CombatMath.apply_armor(amount, enemy.data.armor)
	enemy.hp -= damage
	enemy.set_flash(Enemy.FLASH_TIME)
	enemy.knockback += direction * knockback_force * enemy.data.knockback_taken
	enemy_damaged.emit(enemy.position, damage, crit)
	if not enemy.is_alive():
		enemy.visible = false
		enemy_killed.emit(enemy.data, enemy.position)


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
		var pos := enemy.position
		var to_player := player_pos - pos
		var velocity := to_player.normalized() * enemy.data.speed

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
		if enemy.data.shape_sides >= 3:
			enemy.rotation = velocity.angle()

		if enemy.flash > 0.0:
			enemy.set_flash(maxf(enemy.flash - delta, 0.0))

		var touch := enemy.radius + player_radius
		if to_player.length_squared() <= touch * touch:
			_player.take_damage(enemy.data.contact_damage)


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
