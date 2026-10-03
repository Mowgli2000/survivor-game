extends GutTest
## Plays the real run scene headless for a while with a bot, at accelerated speed.

const RUN_SCENE := preload("res://src/run/run.tscn")

var _run: Run
var _time: float = 0.0


func before_each() -> void:
	_time = 0.0
	Engine.time_scale = 4.0
	_run = _new_run(false, true)
	add_child_autofree(_run)


func after_each() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false


func _new_run(short_stage: bool, auto_choose: bool) -> Run:
	var run: Run = RUN_SCENE.instantiate()
	run.seed_override = 12345
	run.player_invincible = true
	run.auto_choose_upgrades = auto_choose
	run.bot_input = _bot_input
	if short_stage:
		_use_short_stage(run)
	return run


## 3 short waves so a whole run fits in a test.
func _use_short_stage(run: Run) -> void:
	var config: RunConfig = ContentDB.get_def(&"runs", Run.DEFAULT_CONFIG_ID).duplicate()
	var stage: StageData = config.stage.duplicate()
	stage.wave_count = 3
	stage.duration_first = 2.0
	stage.duration_last = 2.0
	stage.duration_step = 0.0
	stage.final_wave_duration = 0.0
	stage.events = []
	config.stage = stage
	run.config = config


## Replaces the default run by a fresh one.
func _swap_run(short_stage: bool, auto_choose: bool) -> Run:
	_run.queue_free()
	_run = _new_run(short_stage, auto_choose)
	add_child_autofree(_run)
	return _run


func _end_wave() -> void:
	_run.waves.time_left = 0.01
	await wait_physics_frames(2)


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
	_run.waves.start_wave(6)  # every enemy type can spawn (ranged, tank)
	await wait_physics_frames(360)  # ~24 s of game time
	assert_gt(_run.state.kills, 20, "the arsenal kills enemies")
	assert_false(_run.state.is_over)


func test_level_ups_are_deferred_to_wave_end() -> void:
	await wait_physics_frames(2)
	_run.progression.add_xp(200)
	assert_gt(_run.progression.pending_level_ups, 0, "level-ups wait for the wave end")
	assert_false(get_tree().paused, "no pause during a wave")
	await _end_wave()
	assert_eq(_run.progression.pending_level_ups, 0, "every level-up consumed at wave end")
	assert_eq(_run.waves.wave, 2, "auto mode starts the next wave")
	assert_true(_run.waves.in_wave)


func test_level_ups_offer_stats_only() -> void:
	await wait_physics_frames(2)
	_run.progression.add_xp(5000)
	await _end_wave()
	assert_eq(_run.progression.pending_level_ups, 0, "every level-up consumed")
	assert_eq(_run.player.weapons.slot_count(), 1, "weapons only come from the shop")


func test_wave_end_clears_heals_and_collects() -> void:
	await wait_physics_frames(60)
	assert_gt(_run.enemies.active_count(), 0)
	_run.player.invincible = false
	_run.player.take_damage(30.0)
	_run.player.invincible = true
	_run.pickups.spawn_xp(_run.player.global_position + Vector2(800, 0), 3)
	watch_signals(_run.pickups)
	await _end_wave()
	assert_lt(_run.enemies.active_count(), 5, "previous enemies removed (a few new ones may spawn)")
	assert_eq(_run.pickups.active_count(), 0, "gems collected")
	assert_almost_eq(_run.player.hp, _run.player.stats.get_value(StatIds.MAX_HP), 0.001, "healed")
	assert_signal_emitted(_run.pickups, "xp_collected", "gem XP collected")
	assert_gt(_run.state.wallet.amount, 0, "gems also give materials")


func test_manual_wave_end_level_ups_then_shop_then_next_wave() -> void:
	var run := _swap_run(true, false)
	await wait_physics_frames(2)
	run.progression.add_xp(20)
	await _end_wave()
	assert_true(get_tree().paused)
	assert_true(run.wave_end_screen.visible)
	assert_true(run.level_up_screen.visible, "pending level-ups are offered")
	assert_false(run.shop_screen.visible, "shop waits for the level-ups")
	while run.level_up_screen.visible:
		run.level_up_screen.offer_chosen.emit(run.level_up_screen._offers[0])
		await wait_process_frames(1)
	assert_true(run.shop_screen.visible, "shop after the level-ups")
	assert_eq(run.shop.offers.size(), run.config.shop.slot_count)
	run.shop_screen.next_wave_requested.emit()
	await wait_physics_frames(2)
	assert_false(get_tree().paused)
	assert_false(run.shop_screen.visible)
	assert_false(run.wave_end_screen.visible)
	assert_eq(run.waves.wave, 2)


func test_run_starts_with_materials() -> void:
	await wait_physics_frames(1)
	assert_eq(_run.state.wallet.amount, _run.config.shop.starting_materials)


func test_auto_mode_buys_in_the_shop() -> void:
	await wait_physics_frames(2)
	_run.state.wallet.add(1000)
	await _end_wave()
	var bought := _run.inventory.get_items().size() + _run.player.weapons.slot_count() - 1
	assert_gt(bought, 0, "something was bought")
	assert_eq(_run.waves.wave, 2)


func test_level_up_reroll_costs_materials() -> void:
	var run := _swap_run(true, false)
	await wait_physics_frames(2)
	run.progression.add_xp(20)
	await _end_wave()
	assert_true(run.level_up_screen.visible)
	assert_eq(run.level_up_screen._offers.size(), run.config.upgrade_choices)
	var before := run.state.wallet.amount
	run.level_up_screen.reroll_requested.emit()
	await wait_process_frames(1)
	assert_eq(run.state.wallet.amount, before - run.config.shop.reroll_cost(1, 0))
	assert_true(run.level_up_screen.visible)


func test_shop_shows_the_stats_panel() -> void:
	var run := _swap_run(true, false)
	await wait_physics_frames(2)
	await _end_wave()
	assert_true(run.shop_screen.visible)
	assert_true(run.shop_screen.stats_panel.is_visible_in_tree())


func test_last_wave_wins_the_run() -> void:
	var run := _swap_run(true, true)
	await wait_physics_frames(2)
	for i in 2:
		await _end_wave()
	assert_false(run.state.is_over, "the last wave is still to be played")
	assert_eq(run.waves.wave, 3)
	assert_true(run.waves.in_wave)
	await _end_wave()
	assert_true(run.state.is_over)
	assert_true(get_tree().paused)
	assert_true(run.game_over_screen.visible)
	assert_true(run.game_over_screen.is_victory)


func test_killing_the_boss_wins_before_the_timer() -> void:
	var run := _swap_run(true, true)
	await wait_physics_frames(2)
	for i in 2:
		await _end_wave()
	run.waves.time_left = 1000.0
	var boss := run.enemies.spawn(ContentDB.get_def(&"enemies", &"shogun"), run.player.position + Vector2(600, 0))
	await wait_physics_frames(2)
	assert_false(run.state.is_over, "boss alive: the wave goes on")
	var index := run.enemies.active_count() - 1
	for i in run.enemies.active_count():
		if run.enemies.get_enemy(i) == boss:
			index = i
	run.enemies.damage_enemy(index, 1.0e9, false, Vector2.RIGHT, 0.0)
	await wait_physics_frames(3)
	assert_true(run.state.is_over)
	assert_true(run.game_over_screen.is_victory)


func test_death_on_wave_end_keeps_game_over() -> void:
	await wait_physics_frames(2)
	_run.player.invincible = false
	_run.player.take_damage(100000.0)
	_run.waves.time_left = 0.01
	await wait_physics_frames(3)
	assert_true(_run.game_over_screen.visible)
	assert_false(_run.game_over_screen.is_victory)
	assert_false(_run.wave_end_screen.visible)
	assert_eq(_run.player.hp, 0.0, "no heal after death")


func test_player_death_ends_the_run() -> void:
	await wait_physics_frames(2)
	_run.player.invincible = false
	_run.player.take_damage(100000.0)
	assert_true(_run.state.is_over)
	assert_true(get_tree().paused)
	assert_true(_run.game_over_screen.visible)


func test_player_and_enemies_are_depth_sorted_together() -> void:
	var actors := _run.player.get_parent() as Node2D
	assert_not_null(actors)
	assert_true(actors.y_sort_enabled, "actors container sorts by y")
	assert_eq(_run.enemies.get_parent(), actors)
	assert_true(_run.enemies.y_sort_enabled, "enemies join the parent's y-sort")


func test_hud_shows_one_icon_per_weapon() -> void:
	await wait_frames(2)
	var tiles := _run.hud._weapons_box.get_children().filter(func(c: Node) -> bool: return c is IconTile)
	assert_eq(tiles.size(), _run.player.weapons.slot_count())
	assert_gt(tiles.size(), 0)


func test_camera_uses_the_configured_zoom() -> void:
	var zoom := _run.config.camera_zoom
	assert_gt(zoom, 0.0)
	assert_eq(_run.player.camera.zoom, Vector2(zoom, zoom))


func test_screens_use_the_shared_theme() -> void:
	var theme := UiTheme.get_theme()
	assert_same(_run.hud.get_child(0).theme, theme, "HUD")
	for screen: CanvasLayer in [_run.level_up_screen, _run.shop_screen, _run.wave_end_screen,
			_run.game_over_screen]:
		assert_same(_ui_root(screen).theme, theme, screen.name)


func _ui_root(screen: CanvasLayer) -> Control:
	for child in screen.get_children():
		if child is Control and (child as Control).theme != null:
			return child
	return screen.get_child(0) as Control


func test_starting_weapon_counts_for_its_family() -> void:
	var weapon := _run.config.character.starting_weapon
	assert_eq(_run.weapon_families.count(weapon.families[0]), 1)
