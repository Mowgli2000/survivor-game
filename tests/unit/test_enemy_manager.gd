extends GutTest
## EnemyManager + ProjectileManager working together, without the full run.

var _player: Player
var _enemies: EnemyManager
var _projectiles: ProjectileManager
var _data: EnemyData


func before_each() -> void:
	var arena := Rect2(-1000, -1000, 2000, 2000)
	_player = Player.new()
	_player.setup(CharacterData.new(), arena)
	_player.invincible = true
	_player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(_player)
	_enemies = EnemyManager.new()
	_enemies.setup(_player, arena, 4)
	add_child_autofree(_enemies)
	_projectiles = ProjectileManager.new()
	_projectiles.setup(_enemies, arena, 4)
	add_child_autofree(_projectiles)
	_data = EnemyData.new()
	_data.max_hp = 10.0
	_data.speed = 0.0
	_data.radius = 16.0


func test_damage_kills_and_emits() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_data, Vector2(500, 0))
	_enemies.damage_enemy(0, 4.0, false, Vector2.RIGHT, 0.0)
	assert_eq(_enemies.get_enemy(0).hp, 6.0)
	_enemies.damage_enemy(0, 10.0, true, Vector2.RIGHT, 0.0)
	assert_signal_emit_count(_enemies, "enemy_killed", 1)
	_enemies.damage_enemy(0, 10.0, false, Vector2.RIGHT, 0.0)
	assert_signal_emit_count(_enemies, "enemy_killed", 1, "dead enemy cannot die twice")


func test_dead_enemies_are_recycled() -> void:
	_enemies.spawn(_data, Vector2(500, 0))
	_enemies.spawn(_data, Vector2(-500, 0))
	_enemies.damage_enemy(0, 100.0, false, Vector2.ZERO, 0.0)
	await wait_physics_frames(2)
	assert_eq(_enemies.active_count(), 1)
	assert_eq(_enemies.get_enemy(0).position, Vector2(-500, 0))


func test_find_nearest_after_grid_rebuild() -> void:
	_enemies.spawn(_data, Vector2(300, 0))
	_enemies.spawn(_data, Vector2(100, 0))
	await wait_physics_frames(1)
	var index := _enemies.find_nearest(Vector2.ZERO, 1000.0)
	assert_almost_eq(_enemies.get_enemy(index).position.x, 100.0, 1.0)
	assert_eq(_enemies.find_nearest(Vector2.ZERO, 50.0), -1)


func test_projectile_hits_and_pierce() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_data, Vector2(200, 0))
	_enemies.spawn(_data, Vector2(300, 0))
	await wait_physics_frames(1)
	# Pierce 1: hits both enemies in a line then disappears.
	_projectiles.spawn(Vector2(150, 0), Vector2(600, 0), 3.0, false, 1, 0.0, 6.0, 2.0, Color.WHITE)
	await wait_physics_frames(30)
	assert_signal_emit_count(_enemies, "enemy_damaged", 2)
	assert_eq(_projectiles.active_count(), 0)
