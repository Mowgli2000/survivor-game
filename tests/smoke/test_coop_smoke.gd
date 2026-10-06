extends GutTest
## Local coop (ADR 0017): the real run scene with two players driven by bots.

const RUN_SCENE := preload("res://src/run/run.tscn")

var _run: Run
var _time: float = 0.0


func before_each() -> void:
	_time = 0.0
	Engine.time_scale = 4.0


func after_each() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false


func _start(auto_choose: bool) -> Run:
	_run = RUN_SCENE.instantiate()
	_run.seed_override = 4321
	_run.player_invincible = true
	_run.auto_choose_upgrades = auto_choose
	_run.player_count = 2
	_run.bot_input = func() -> Vector2:
		_time += get_physics_process_delta_time() * Engine.time_scale
		return Vector2.from_angle(_time * 0.6)
	add_child_autofree(_run)
	return _run


func _end_wave() -> void:
	_run.waves.time_left = 0.01
	await wait_physics_frames(2)


func test_two_players_with_their_own_belongings() -> void:
	var run := _start(true)
	await wait_physics_frames(2)
	assert_eq(run.players.size(), 2)
	assert_eq(run.party.size(), 2)
	var p1 := run.players[0]
	var p2 := run.players[1]
	assert_eq(p1.player, run.player, "legacy fields are player 1's")
	assert_ne(p1.wallet, p2.wallet)
	assert_ne(p1.progression, p2.progression)
	assert_ne(p1.shop, p2.shop)
	assert_ne(p1.shop_screen, p2.shop_screen)
	assert_eq(p2.player.index, 1)
	assert_eq(p2.player.weapons.slot_count(), 1, "player 2 has its starting weapon")
	assert_eq(p2.wallet.amount, run.config.shop.starting_materials)


func test_coop_scales_the_stage() -> void:
	var run := _start(true)
	await wait_physics_frames(1)
	var base := run.config.stage
	assert_almost_eq(run.stage.spawn_rate_first, base.spawn_rate_first * run.config.coop_spawn_multiplier, 0.001)
	assert_almost_eq(run.stage.hp_multiplier_first, base.hp_multiplier_first * run.config.coop_hp_multiplier, 0.001)


func test_coop_run_plays_without_errors() -> void:
	var run := _start(true)
	await wait_seconds(3.0)
	assert_false(run.state.is_over)
	assert_gt(run.state.wave_spawned, 0, "enemies come for the group")


func test_one_dead_player_waits_for_the_next_wave() -> void:
	var run := _start(true)
	await wait_physics_frames(2)
	var p2 := run.players[1].player
	p2.invincible = false
	p2.take_damage(100000.0)
	assert_true(p2.is_dead)
	assert_false(run.state.is_over, "the other player fights on")
	assert_false(get_tree().paused)
	await _end_wave()
	await wait_physics_frames(2)
	assert_eq(run.waves.wave, 2)
	assert_false(p2.is_dead, "back for the next wave")
	assert_eq(p2.hp, p2.stats.get_value(StatIds.MAX_HP))


func test_run_is_lost_when_both_players_are_dead() -> void:
	var run := _start(true)
	await wait_physics_frames(2)
	for rp in run.players:
		rp.player.invincible = false
		rp.player.take_damage(100000.0)
	assert_true(run.state.is_over)
	assert_true(run.game_over_screen.visible)


func test_between_waves_both_players_act_at_the_same_time() -> void:
	var run := _start(false)
	await wait_physics_frames(2)
	run.players[1].progression.add_xp(20)
	await _end_wave()
	assert_true(get_tree().paused)
	assert_true(run.players[0].shop_screen.visible, "player 1 has no level-up: his shop is open at once")
	assert_true(run.players[1].level_up_screen.visible, "player 2 picks his level-up meanwhile")
	assert_false(run.players[1].shop_screen.visible)
	# Player 1 leaves his shop first: the wave waits for player 2.
	run.players[0].shop_screen.next_wave_requested.emit()
	await wait_process_frames(1)
	assert_true(get_tree().paused, "player 2 is not done")
	var second := run.players[1].level_up_screen
	while second.visible:
		second.offer_chosen.emit(second._offers[0])
		await wait_process_frames(1)
	assert_true(run.players[1].shop_screen.visible)
	run.players[1].shop_screen.next_wave_requested.emit()
	await wait_physics_frames(2)
	assert_false(get_tree().paused)
	assert_eq(run.waves.wave, 2)


func test_each_players_screens_live_in_his_half() -> void:
	var run := _start(true)
	await wait_physics_frames(2)
	assert_not_null(run.coop_screens)
	assert_eq(run.players[0].shop_screen.get_viewport(), run.coop_screens.viewport_of(0))
	assert_eq(run.players[1].level_up_screen.get_viewport(), run.coop_screens.viewport_of(1))


func test_gems_credit_the_player_who_collects_them() -> void:
	var run := _start(true)
	await wait_physics_frames(2)
	var collectors: Array[int] = []
	run.pickups.xp_collected.connect(func(amount: int, collector: int) -> void:
		if amount == 777:
			collectors.append(collector))
	run.pickups.spawn_xp(run.players[1].player.global_position, 777)
	await wait_physics_frames(3)
	assert_eq(collectors, [1] as Array[int], "player 2 took the gem at its feet")
