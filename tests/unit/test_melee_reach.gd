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
