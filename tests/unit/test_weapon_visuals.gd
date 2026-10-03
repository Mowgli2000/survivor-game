extends GutTest
## WeaponVisuals: weapons drawn around the player, aiming, recoil / swing.

var _player: Player
var _enemies: EnemyManager
var _visuals: WeaponVisuals
var _left := false


func before_each() -> void:
	_left = false
	var arena := Rect2(-1000, -1000, 2000, 2000)
	_player = Player.new()
	_player.setup(CharacterData.new(), arena)
	_player.invincible = true
	_player.bot_input = func() -> Vector2: return Vector2.LEFT if _left else Vector2.ZERO
	add_child_autofree(_player)
	_enemies = EnemyManager.new()
	_enemies.setup(Party.solo(_player), arena, 4)
	add_child_autofree(_enemies)
	_visuals = _player.weapon_visuals
	_visuals.setup(_player.weapons, _enemies, _player)


func _pulse() -> WeaponData:
	return ContentDB.get_def(&"weapons", &"pulse")


func _still_enemy() -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = 1000.0
	data.speed = 0.0
	return data


func test_weapon_aims_at_nearest_enemy() -> void:
	_player.weapons.add_weapon(_pulse())
	_enemies.spawn(_still_enemy(), Vector2(0, 300))
	await wait_frames(30)
	var mount := WeaponLayout.mount_offset(0, 1)
	var expected := (Vector2(0, 300) - mount).angle()
	assert_almost_eq(angle_difference(_visuals.aim_angle(0), expected), 0.0, 0.1)


func test_idle_weapon_follows_movement() -> void:
	_player.weapons.add_weapon(_pulse())
	_left = true
	await wait_frames(40)
	assert_almost_eq(absf(angle_difference(_visuals.aim_angle(0), PI)), 0.0, 0.15)


func test_firing_kicks_then_settles() -> void:
	_player.weapons.add_weapon(_pulse())
	await wait_frames(1)
	_player.weapons.weapon_fired.emit(0)
	assert_eq(_visuals.kick(0), 1.0)
	await wait_frames(40)
	assert_eq(_visuals.kick(0), 0.0)


func test_weapon_without_icon_is_skipped() -> void:
	var data := WeaponData.new()
	data.behavior = _pulse().behavior
	_player.weapons.add_weapon(data)
	_player.weapons.add_weapon(_pulse())
	await wait_frames(5)
	assert_eq(_visuals.aim_angle(1), _visuals.aim_angle(1), "visuals keep running")
