extends GutTest
## Melee weapons: the Range stat lengthens the reach at half effect (Brotato rule).


func test_no_range_bonus_keeps_the_base_reach() -> void:
	var stats := StatBlock.from_defaults({})
	assert_almost_eq(MeleeArcBehavior.reach_multiplier(stats), 1.0, 0.001)


func test_range_bonus_counts_half_for_melee() -> void:
	var stats := StatBlock.from_defaults({"range": 1.4})
	assert_almost_eq(MeleeArcBehavior.reach_multiplier(stats), 1.2, 0.001)


func test_the_blow_lands_when_the_swing_strikes_not_when_it_starts() -> void:
	# Playtest 2026-10-09: the slash streak cut an enemy on screen but nothing was hit,
	# because the damage was resolved at the start of the wind-up.
	var arena := Rect2(-1000, -1000, 2000, 2000)
	var player := Player.new()
	player.setup(CharacterData.new(), arena)
	player.invincible = true
	player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(player)
	var rng := RandomNumberGenerator.new()
	var enemies := EnemyManager.new()
	enemies.setup(Party.solo(player), arena, 4, rng, null, null)
	add_child_autofree(enemies)
	var data := EnemyData.new()
	data.max_hp = 100.0
	data.speed = 0.0
	data.radius = 16.0
	enemies.spawn(data, Vector2(80.0, 0.0))
	await wait_physics_frames(2)  # the spatial grid learns the enemy
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"katana")
	var slot := WeaponSlot.new(weapon, 1)
	var ctx := WeaponContext.new(player, StatBlock.from_defaults({}), enemies, null, rng)
	assert_true(weapon.behavior.fire(slot, ctx))
	assert_eq(enemies.get_enemy(0).hp, 100.0, "nothing is hurt during the wind-up")
	await wait_seconds(WeaponVisuals.strike_delay(weapon.slash_style) + 0.15)
	assert_lt(enemies.get_enemy(0).hp, 100.0, "the strike hurts the enemy in the arc")


func test_the_scythe_cuts_where_its_blade_passes() -> void:
	# The orbiting blade sweeps 270 degrees clockwise from straight up (aimed at +x): the gap
	# is up-left, so an enemy there is spared while one on the aimed side is cut.
	var arena := Rect2(-1000, -1000, 2000, 2000)
	var player := Player.new()
	player.setup(CharacterData.new(), arena)
	player.invincible = true
	player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(player)
	var rng := RandomNumberGenerator.new()
	var enemies := EnemyManager.new()
	enemies.setup(Party.solo(player), arena, 4, rng, null, null)
	add_child_autofree(enemies)
	var data := EnemyData.new()
	data.max_hp = 1000.0
	data.speed = 0.0
	data.radius = 12.0
	enemies.spawn(data, Vector2(90.0, 0.0))
	enemies.spawn(data, Vector2(-70.0, -70.0))
	await wait_physics_frames(2)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"scythe")
	var slot := WeaponSlot.new(weapon, 1)
	var ctx := WeaponContext.new(player, StatBlock.from_defaults({}), enemies, null, rng)
	assert_true(weapon.behavior.fire(slot, ctx))
	assert_eq(enemies.get_enemy(0).hp, 1000.0, "nothing is hurt before the blade arrives")
	await wait_seconds(weapon.slash_sheet.duration + 0.2)
	assert_lt(enemies.get_enemy(0).hp, 1000.0, "the blade cuts the enemy it passes over")
	assert_eq(enemies.get_enemy(1).hp, 1000.0, "the enemy in the unswept gap is spared")


## Fires `weapon_id` at an enemy 90 px to the right with `others` more enemies around, waits for every
## delayed hit, and returns the hurt flag of each enemy (the first one is the target).
func _blow_hurts(weapon_id: StringName, others: Array[Vector2]) -> Array[bool]:
	var arena := Rect2(-1000, -1000, 2000, 2000)
	var player := Player.new()
	player.setup(CharacterData.new(), arena)
	player.invincible = true
	player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(player)
	var rng := RandomNumberGenerator.new()
	var enemies := EnemyManager.new()
	enemies.setup(Party.solo(player), arena, 4, rng, null, null)
	add_child_autofree(enemies)
	var data := EnemyData.new()
	data.max_hp = 5000.0
	data.speed = 0.0
	data.radius = 10.0
	enemies.spawn(data, Vector2(90.0, 0.0))
	for position in others:
		enemies.spawn(data, position)
	await wait_physics_frames(2)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", weapon_id)
	var slot := WeaponSlot.new(weapon, 1)
	var ctx := WeaponContext.new(player, StatBlock.from_defaults({}), enemies, null, rng)
	assert_true(weapon.behavior.fire(slot, ctx))
	await wait_seconds(1.2)
	var hurt: Array[bool] = []
	for i in others.size() + 1:
		hurt.append(enemies.get_enemy(i).hp < 5000.0)
	return hurt


func test_the_cut_line_hurts_what_it_crosses_not_what_is_beside_it() -> void:
	var hurt := await _blow_hurts(&"steel_katana", [Vector2(130.0, 3.0), Vector2(100.0, 70.0), Vector2(-150.0, 0.0)])
	assert_true(hurt[0] and hurt[1], "enemies on the line are cut")
	assert_false(hurt[2], "an enemy beside the line is spared")
	assert_false(hurt[3], "an enemy behind the wielder is spared")


func test_the_axe_slam_hurts_a_circle_on_the_target_only() -> void:
	var hurt := await _blow_hurts(&"heavy_axe", [Vector2(120.0, 10.0), Vector2(90.0, 200.0), Vector2(-150.0, 0.0)])
	assert_true(hurt[0] and hurt[1], "the target and its neighbor are slammed")
	assert_false(hurt[2], "an enemy far from the slam is spared")
	assert_false(hurt[3], "the slam does not reach behind the wielder")


func test_the_fire_wave_hurts_what_it_passes_over() -> void:
	var hurt := await _blow_hurts(&"katana", [Vector2(150.0, 0.0), Vector2(180.0, 200.0), Vector2(-150.0, 0.0)])
	assert_true(hurt[0] and hurt[1], "enemies on the wave's path are burnt")
	assert_false(hurt[2], "an enemy off the path is spared")
	assert_false(hurt[3], "an enemy behind the wielder is spared")


func test_the_hammer_shockwave_reaches_enemies_around_the_target() -> void:
	var hurt := await _blow_hurts(&"warhammer", [Vector2(160.0, 40.0), Vector2(90.0, 300.0)])
	assert_true(hurt[0] and hurt[1], "the ring hurts the target and what it reaches")
	assert_false(hurt[2], "an enemy outside the ring is spared")


func test_the_rapier_flurry_hurts_a_narrow_fan() -> void:
	var hurt := await _blow_hurts(&"rapier", [Vector2(150.0, 90.0), Vector2(-150.0, 0.0)])
	assert_true(hurt[0], "the target is stabbed")
	assert_false(hurt[1], "an enemy wide of the fan is spared")
	assert_false(hurt[2], "an enemy behind the wielder is spared")
