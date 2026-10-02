extends GutTest
## Plays the real run scene headless for a while with a bot, at accelerated speed.

const RUN_SCENE := preload("res://src/run/run.tscn")

var _run: Run
var _time: float = 0.0


func before_each() -> void:
	_time = 0.0
	Engine.time_scale = 4.0
	_run = RUN_SCENE.instantiate()
	_run.seed_override = 12345
	_run.player_invincible = true
	_run.auto_choose_upgrades = true
	_run.bot_input = _bot_input
	add_child_autofree(_run)


func after_each() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false


## Walks in a slow circle.
func _bot_input() -> Vector2:
	_time += get_physics_process_delta_time() * Engine.time_scale
	return Vector2.from_angle(_time * 0.6)


func test_run_plays_without_errors() -> void:
	await wait_physics_frames(480)  # ~32 s of game time
	assert_gt(_run.state.elapsed, 25.0, "run time advances")
	assert_gt(_run.enemies.active_count(), 0, "enemies spawned")
	assert_gt(_run.state.kills, 0, "the weapon kills enemies")
	assert_false(_run.state.is_over)


func test_all_weapons_at_max_level() -> void:
	await wait_physics_frames(2)
	for def in ContentDB.get_all(&"weapons"):
		var weapon := def as WeaponData
		_run.player.weapons.add_weapon(weapon, weapon.max_level())
	_run.state.elapsed = 90.0  # every enemy type can spawn (ranged, tank)
	await wait_physics_frames(360)  # ~24 s of game time
	assert_gt(_run.state.kills, 20, "the arsenal kills enemies")
	assert_false(_run.state.is_over)


func test_level_ups_offer_weapons_and_stats() -> void:
	await wait_physics_frames(2)
	_run.progression.add_xp(5000)
	assert_eq(_run.progression.pending_level_ups, 0, "every level-up consumed")
	var weapon_levels := 0
	for slot in _run.player.weapons.get_slots():
		weapon_levels += slot.level
	assert_gt(weapon_levels, 1, "weapons were gained or levelled up")
	assert_lte(_run.player.weapons.slot_count(), _run.config.max_weapon_slots)


func test_level_up_applies_an_upgrade() -> void:
	await wait_physics_frames(2)
	_run.progression.add_xp(200)
	assert_gt(_run.progression.level, 3)
	assert_eq(_run.progression.pending_level_ups, 0, "every level-up consumed")
	assert_false(get_tree().paused)


func test_player_death_ends_the_run() -> void:
	await wait_physics_frames(2)
	_run.player.invincible = false
	_run.player.take_damage(100000.0)
	assert_true(_run.state.is_over)
	assert_true(get_tree().paused)
	assert_true(_run.game_over_screen.visible)
