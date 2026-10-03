extends GutTest
## Local coop building blocks (ADR 0017): Party, PlayerInput, damage attribution,
## enemies chasing the nearest living player.

const ARENA := Rect2(-3000, -3000, 6000, 6000)


func _player_at(pos: Vector2, index: int = 0) -> Player:
	var player := Player.new()
	var character := CharacterData.new()
	character.invulnerability_time = 0.0
	player.setup(character, ARENA)
	player.index = index
	player.position = pos
	player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(player)
	return player


func _enemy_data() -> EnemyData:
	var data := EnemyData.new()
	data.id = &"test_grunt"
	data.max_hp = 10.0
	data.speed = 100.0
	data.radius = 10.0
	data.contact_damage = 0.0
	return data


# --- Party ------------------------------------------------------------------

func test_party_nearest_alive_skips_the_dead() -> void:
	var near := _player_at(Vector2(10, 0))
	var far := _player_at(Vector2(500, 0), 1)
	var party := Party.new()
	party.add(near)
	party.add(far)
	assert_eq(party.nearest_alive(Vector2.ZERO), near)
	near.is_dead = true
	assert_eq(party.nearest_alive(Vector2.ZERO), far)
	far.is_dead = true
	assert_null(party.nearest_alive(Vector2.ZERO))


func test_party_center_of_the_living() -> void:
	var a := _player_at(Vector2(0, 0))
	var b := _player_at(Vector2(200, 100), 1)
	var party := Party.new()
	party.add(a)
	party.add(b)
	assert_eq(party.center(), Vector2(100, 50))
	b.is_dead = true
	assert_eq(party.center(), Vector2(0, 0), "a ghost does not pull the camera")


func test_players_cannot_walk_away_from_each_other() -> void:
	var a := _player_at(Vector2.ZERO)
	var b := _player_at(Vector2(Party.MAX_SPREAD - 10.0, 0), 1)
	var party := Party.new()
	party.add(a)
	party.add(b)
	a.party = party
	b.party = party
	b.stats.set_base(StatIds.MOVE_SPEED, 600.0)
	b.bot_input = func() -> Vector2: return Vector2.RIGHT
	await wait_physics_frames(10)
	assert_almost_eq(b.global_position.distance_to(a.global_position), Party.MAX_SPREAD, 0.5)


# --- PlayerInput ------------------------------------------------------------

func test_input_assignment_with_two_pads() -> void:
	var inputs := PlayerInput.assign(2, [3, 7] as Array[int])
	assert_eq(inputs[0].device, 3)
	assert_true(inputs[0].keyboard)
	assert_eq(inputs[1].device, 7)
	assert_false(inputs[1].keyboard)


func test_input_assignment_with_one_pad() -> void:
	var inputs := PlayerInput.assign(2, [5] as Array[int])
	assert_eq(inputs[0].device, -1, "player 1 on the keyboard")
	assert_true(inputs[0].keyboard)
	assert_eq(inputs[1].device, 5)


func test_solo_input_uses_the_plain_actions() -> void:
	var inputs := PlayerInput.assign(1, [0, 1] as Array[int])
	assert_true(inputs[0].shared)
	assert_eq(inputs[0].actions(), PlayerInput.MOVE_ACTIONS)


func test_coop_actions_hold_only_the_players_devices() -> void:
	var input := PlayerInput.coop(1, 4, false)
	for action in input.actions():
		for event in InputMap.action_get_events(action):
			assert_false(event is InputEventKey, "no keyboard for player 2")
			assert_eq(event.device, 4)


func test_owns_event_by_device() -> void:
	var p2 := PlayerInput.coop(1, 4, false)
	var pad_4 := InputEventJoypadButton.new()
	pad_4.device = 4
	var pad_0 := InputEventJoypadButton.new()
	pad_0.device = 0
	assert_true(p2.owns_event(pad_4))
	assert_false(p2.owns_event(pad_0))
	assert_false(p2.owns_event(InputEventKey.new()))
	assert_true(PlayerInput.coop(0, 0, true).owns_event(InputEventKey.new()))


# --- Enemies and attribution ------------------------------------------------

func _enemies_for(party: Party) -> EnemyManager:
	var enemies := EnemyManager.new()
	enemies.setup(party, ARENA, 4)
	add_child_autofree(enemies)
	return enemies


func test_enemies_chase_the_nearest_living_player() -> void:
	var left := _player_at(Vector2(-400, 0))
	var right := _player_at(Vector2(400, 0), 1)
	var party := Party.new()
	party.add(left)
	party.add(right)
	var enemies := _enemies_for(party)
	var enemy := enemies.spawn(_enemy_data(), Vector2(100, 0))
	await wait_physics_frames(5)
	assert_gt(enemy.position.x, 100.0, "toward the right player")
	right.is_dead = true
	var x := enemy.position.x
	await wait_physics_frames(5)
	assert_lt(enemy.position.x, x, "the dead one is ignored")


func test_kills_trigger_only_the_killers_item_effects() -> void:
	var p1 := _player_at(Vector2(-400, 0))
	var p2 := _player_at(Vector2(400, 0), 1)
	var party := Party.new()
	party.add(p1)
	party.add(p2)
	var enemies := _enemies_for(party)
	var wallets: Array[Wallet] = [Wallet.new(), Wallet.new()]
	for i in 2:
		var effects := ItemEffects.new()
		effects.setup(party.members[i], enemies, wallets[i], RandomNumberGenerator.new())
		add_child_autofree(effects)
		var effect := MaterialOnKillEffect.new()
		effect.chance = 1.0
		effects.add_effects([effect] as Array[ItemEffect])
	enemies.spawn(_enemy_data(), Vector2(0, 500))
	enemies.damage_source = 1
	enemies.damage_enemy(0, 1000.0, false, Vector2.RIGHT, 0.0)
	assert_eq(wallets[1].amount, 1, "player 2 killed it")
	assert_eq(wallets[0].amount, 0)


func test_burn_ticks_belong_to_the_player_who_set_it() -> void:
	var party := Party.solo(_player_at(Vector2(-2000, 0)))
	var enemies := _enemies_for(party)
	enemies.spawn(_enemy_data(), Vector2(0, 500))
	var burn := StatusData.new()
	burn.type = StatusData.Type.BURN
	burn.power = 1.0
	burn.duration = 2.0
	enemies.damage_source = 1
	enemies.damage_enemy(0, 1.0, false, Vector2.RIGHT, 0.0, burn, 1.0)
	enemies.damage_source = 0
	await wait_physics_frames(2)
	assert_eq(enemies.damage_source, 1, "burn ticks are player 2's damage")
