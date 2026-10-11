extends GutTest
## WeaponHolder: slots, copies, merging.


func test_copies_of_one_weapon_start_out_of_step() -> void:
	var holder := WeaponHolder.new()
	autofree(holder)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"katana")
	var first := holder.add_weapon(weapon)
	var second := holder.add_weapon(weapon)
	var third := holder.add_weapon(weapon)
	assert_eq(first.cooldown, 0.0)
	assert_gt(second.cooldown, 0.0, "the second copy waits")
	assert_ne(second.cooldown, third.cooldown, "each copy has its own phase")


func test_copies_get_a_rank_and_a_count() -> void:
	var holder := WeaponHolder.new()
	autofree(holder)
	var katana: WeaponData = ContentDB.get_def(&"weapons", &"katana")
	var spear: WeaponData = ContentDB.get_def(&"weapons", &"spear")
	var a := holder.add_weapon(katana)
	var b := holder.add_weapon(spear)
	var c := holder.add_weapon(katana)
	assert_eq([a.copy_rank, c.copy_rank, b.copy_rank], [0, 1, 0])
	assert_eq([a.copy_count, c.copy_count, b.copy_count], [2, 2, 1])


func test_copies_never_attack_together_even_after_an_idle_spell() -> void:
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
	var holder := WeaponHolder.new()
	add_child_autofree(holder)
	var ctx := WeaponContext.new(player, StatBlock.from_defaults({}), enemies, null, rng)
	holder.setup(ctx)
	var katana: WeaponData = ContentDB.get_def(&"weapons", &"katana")
	holder.add_weapon(katana)
	holder.add_weapon(katana)
	await wait_seconds(1.5)  # no enemy: both copies sit ready
	var data := EnemyData.new()
	data.max_hp = 100000.0
	data.speed = 0.0
	data.radius = 10.0
	enemies.spawn(data, Vector2(120.0, 0.0))
	enemies.spawn(data, Vector2(-130.0, 40.0))
	var fired: Array[float] = []
	holder.weapon_fired.connect(func(_i: int) -> void: fired.append(Time.get_ticks_msec() / 1000.0))
	await wait_seconds(3.0)
	assert_gte(fired.size(), 4, "both copies attack")
	var gap := holder.get_slots()[0].stats.cooldown / ctx.stats.get_value(StatIds.ATTACK_SPEED) / 2.0
	for i in range(1, fired.size()):
		assert_gt(fired[i] - fired[i - 1], gap * 0.8, "copies are about half a cooldown apart")
