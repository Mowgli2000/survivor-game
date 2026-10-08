extends GutTest

var _player: Player


func before_each() -> void:
	var data := CharacterData.new()
	data.stat_overrides = {"max_hp": 50.0}
	data.invulnerability_time = 0.5
	_player = Player.new()
	_player.setup(data, Rect2(-100, -100, 200, 200))
	add_child_autofree(_player)


func test_damage_and_invulnerability() -> void:
	watch_signals(_player)
	_player.take_damage(10.0)
	assert_eq(_player.hp, 40.0)
	assert_true(_player.is_invulnerable())
	_player.take_damage(10.0)
	assert_eq(_player.hp, 40.0, "second hit ignored during invulnerability")
	assert_signal_emit_count(_player, "damaged", 1)


func test_death_emits_once() -> void:
	watch_signals(_player)
	_player.take_damage(999.0)
	assert_true(_player.is_dead)
	assert_eq(_player.hp, 0.0)
	assert_signal_emit_count(_player, "died", 1)


func test_invincible_flag() -> void:
	_player.invincible = true
	_player.take_damage(999.0)
	assert_eq(_player.hp, 50.0)


func test_max_hp_upgrade_heals_by_gain() -> void:
	_player.take_damage(20.0)
	var mod := StatModifier.new()
	mod.stat = StatIds.MAX_HP
	mod.flat = 20.0
	_player.stats.add_modifier(mod)
	assert_eq(_player.stats.get_value(StatIds.MAX_HP), 70.0)
	assert_eq(_player.hp, 50.0)


func test_heal_is_capped() -> void:
	_player.take_damage(5.0)
	_player.heal(100.0)
	assert_eq(_player.hp, 50.0)


func test_player_sprite_faces_movement() -> void:
	var data := CharacterData.new()
	data.sprite_id = &"drifter"
	var player := Player.new()
	player.setup(data, Rect2(-500, -500, 1000, 1000))
	player.bot_input = func() -> Vector2: return Vector2.LEFT
	add_child_autofree(player)
	assert_not_null(player.animator.sheet)
	await wait_physics_frames(3)
	assert_eq(player.animator.facing, -1.0)
	assert_eq(player.animator.animation, &"walk")


func test_walk_cycle_follows_the_movement_speed() -> void:
	assert_almost_eq(Player.walk_anim_rate(Player.WALK_ANIM_SPEED), 1.0, 0.001, "drawn speed at the base speed")
	assert_gt(Player.walk_anim_rate(450.0), 1.0, "a faster hunter steps faster")
	assert_eq(Player.walk_anim_rate(5000.0), Player.WALK_RATE_MAX, "never frantic")
	assert_eq(Player.walk_anim_rate(10.0), Player.WALK_RATE_MIN)


func test_arrival_from_the_gate_blocks_hits_and_movement_until_it_lands() -> void:
	watch_signals(_player)
	_player.bot_input = func() -> Vector2: return Vector2.RIGHT
	_player.enter_from(Vector2(0.0, -400.0))
	_player.take_damage(10.0)
	assert_eq(_player.hp, 50.0, "no damage while dropping")
	await wait_physics_frames(3)
	assert_eq(_player.position, Vector2.ZERO, "no walking while dropping")
	assert_false(_player.weapon_visuals.visible)
	await wait_seconds(Player.ARRIVAL_SECONDS + 0.2)
	assert_signal_emitted(_player, "landed")
	assert_true(_player.weapon_visuals.visible)
	_player.take_damage(10.0)
	assert_eq(_player.hp, 40.0, "hits count again once landed")
