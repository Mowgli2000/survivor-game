extends GutTest
## Charger, kamikaze and spawner behaviors inside EnemyManager's loop (step 5b).

const DT := 0.05

var _player: Player
var _enemies: EnemyManager


func before_each() -> void:
	var arena := Rect2(-2000, -2000, 4000, 4000)
	_player = Player.new()
	_player.setup(CharacterData.new(), arena)
	_player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(_player)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	_enemies = EnemyManager.new()
	_enemies.setup(Party.solo(_player), arena, 4, rng)
	add_child_autofree(_enemies)


func _step(seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		_enemies._physics_process(DT)
		t += DT


func _charger() -> EnemyData:
	var data := EnemyData.new()
	data.movement = EnemyData.Movement.CHARGER
	data.max_hp = 20.0
	data.speed = 100.0
	data.charge_range = 300.0
	data.charge_windup = 0.5
	data.charge_speed = 800.0
	data.charge_duration = 0.4
	data.charge_cooldown = 2.0
	return data


func _kamikaze() -> EnemyData:
	var data := EnemyData.new()
	data.movement = EnemyData.Movement.KAMIKAZE
	data.max_hp = 5.0
	data.speed = 0.0
	data.contact_damage = 0.0
	data.fuse_range = 80.0
	data.fuse_time = 0.5
	data.blast_radius = 120.0
	data.blast_damage = 20.0
	return data


func test_charger_stops_to_telegraph_then_rushes_at_the_player() -> void:
	var enemy := _enemies.spawn(_charger(), Vector2(250, 0))
	_step(DT)
	assert_gt(enemy.forced_time, 0.0, "windup started in range")
	assert_eq(enemy.forced_velocity, Vector2.ZERO, "stands still while telegraphing")
	var before := enemy.position
	_step(0.55)
	assert_almost_eq(enemy.forced_velocity.x, -800.0, 1.0, "rushes towards the player")
	_step(0.2)
	assert_lt(enemy.position.x, before.x - 100.0)


func test_charger_out_of_range_just_walks() -> void:
	var enemy := _enemies.spawn(_charger(), Vector2(900, 0))
	_step(DT)
	assert_eq(enemy.forced_time, 0.0)
	assert_lt(enemy.position.x, 900.0)


func test_kamikaze_explodes_after_its_fuse_and_hurts_in_range() -> void:
	watch_signals(_enemies)
	var enemy := _enemies.spawn(_kamikaze(), Vector2(60, 0))
	var hp := _player.hp
	_step(0.3)
	assert_true(enemy.is_alive(), "still burning its fuse")
	assert_eq(_player.hp, hp)
	_step(0.3)
	assert_false(enemy.is_alive())
	assert_almost_eq(_player.hp, hp - 20.0, 0.01)
	assert_signal_not_emitted(_enemies, "enemy_killed", "self-destruct gives no XP")


func test_kamikaze_blast_misses_a_player_who_ran_away() -> void:
	var enemy := _enemies.spawn(_kamikaze(), Vector2(60, 0))
	var hp := _player.hp
	_step(DT)
	_player.global_position = Vector2(-400, 0)
	_step(0.6)
	assert_false(enemy.is_alive())
	assert_eq(_player.hp, hp)


func test_spawner_calls_minions_with_its_hp_scaling_and_respects_the_cap() -> void:
	var minion := EnemyData.new()
	minion.max_hp = 10.0
	var data := EnemyData.new()
	data.movement = EnemyData.Movement.SPAWNER
	data.max_hp = 40.0
	data.speed = 0.0
	data.spawn_enemy = minion
	data.spawn_count = 3
	data.spawn_cooldown = 1.0
	_enemies.spawn(data, Vector2(500, 0), 2.0)
	_step(0.5)
	assert_eq(_enemies.active_count(), 1)
	_step(0.6)
	assert_eq(_enemies.active_count(), 4)
	assert_almost_eq(_enemies.get_enemy(1).max_hp, 20.0, 0.01, "minions share the wave HP scaling")
	_enemies.spawn_cap = 5
	_step(1.0)
	assert_eq(_enemies.active_count(), 4, "no room for a whole group under the cap")
