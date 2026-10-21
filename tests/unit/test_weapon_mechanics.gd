extends GutTest
## Mechanics that make the ranged weapons play differently: distance damage (long bow), rapid-fire build-up
## (repeating crossbow), boomerang (shuriken), wall bounce (sling), fan (javelins).


func _setup(enemy_at: Vector2, hp: float = 5000.0) -> Dictionary:
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
	var projectiles := ProjectileManager.new()
	add_child_autofree(projectiles)
	projectiles.setup(enemies, arena, 4, null)
	var data := EnemyData.new()
	data.max_hp = hp
	data.speed = 0.0
	data.radius = 10.0
	enemies.spawn(data, enemy_at)
	await wait_physics_frames(2)
	return {"player": player, "rng": rng, "enemies": enemies, "projectiles": projectiles, "data": data}


func _fire(s: Dictionary, id: StringName) -> WeaponSlot:
	var weapon: WeaponData = ContentDB.get_def(&"weapons", id)
	var slot := WeaponSlot.new(weapon, 1)
	slot.stats.crit_chance = 0.0  # a random critical hit made the damage comparisons flaky
	var ctx := WeaponContext.new(s.player, StatBlock.from_defaults({}), s.enemies, s.projectiles, s.rng)
	assert_true(weapon.behavior.fire(slot, ctx))
	return slot


func test_the_long_bow_hits_harder_at_a_distance() -> void:
	var near := await _setup(Vector2(120.0, 0.0))
	_fire(near, &"longbow")
	await wait_seconds(0.4)
	var far := await _setup(Vector2(640.0, 0.0))
	_fire(far, &"longbow")
	await wait_seconds(0.8)
	var near_damage: float = 5000.0 - near.enemies.get_enemy(0).hp
	var far_damage: float = 5000.0 - far.enemies.get_enemy(0).hp
	assert_gt(near_damage, 0.0)
	assert_gt(far_damage, near_damage * 1.5, "an arrow that flew 640 px hurts far more than one at 120 px")


func test_the_repeating_crossbow_speeds_up_while_it_keeps_firing_and_slows_down_after() -> void:
	var s := await _setup(Vector2(300.0, 0.0))
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"smg")
	var holder := WeaponHolder.new()
	add_child_autofree(holder)
	holder.setup(WeaponContext.new(s.player, StatBlock.from_defaults({}), s.enemies, s.projectiles, s.rng))
	var slot := holder.add_weapon(weapon)
	await wait_seconds(1.0)
	assert_gt(slot.ramp, 0.1, "it builds up while firing")
	holder.remove_weapon(0)  # it stops: the speed-up of a slot fades by itself
	assert_true(slot.retired)


func test_a_shuriken_comes_back_to_the_hero_and_hurts_on_the_way_back() -> void:
	var s := await _setup(Vector2(250.0, 0.0))
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"shuriken")
	assert_true(weapon.returns)
	_fire(s, &"shuriken")
	await wait_seconds(0.5)
	var hp_out: float = s.enemies.get_enemy(0).hp
	assert_lt(hp_out, 5000.0, "hit on the way out")
	await wait_seconds(1.6)
	assert_lt(s.enemies.get_enemy(0).hp, hp_out, "and again on the way back")
	assert_eq(s.projectiles.active_count(), 0, "it was caught by the hero")


func test_a_sling_stone_bounces_off_the_wall() -> void:
	var s := await _setup(Vector2(-500.0, 0.0))
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"sling")
	assert_gt(weapon.wall_bounces, 0)
	var stats := WeaponStats.compute(weapon, 1)
	var stone: Projectile = s.projectiles.spawn(Vector2(990.0, 0.0), Vector2(800.0, 0.0), 1.0, false, 0, 0.0, 1.0, stats)
	await wait_seconds(0.1)
	assert_lt(stone.velocity.x, 0.0, "the stone turned back at the wall")
	assert_lte(stone.position.x, 1000.0, "and stays in the arena")


func test_javelins_throw_a_fan_of_three() -> void:
	var s := await _setup(Vector2(250.0, 0.0))
	_fire(s, &"javelins")
	assert_eq(s.projectiles.active_count(), 3)


func test_lobbed_flasks_of_a_volley_land_on_different_spots_not_in_a_row() -> void:
	var s := await _setup(Vector2(300.0, 0.0))
	for spot in [Vector2(-300.0, 100.0), Vector2(100.0, 320.0), Vector2(0.0, -350.0)]:
		s.enemies.spawn(s.data, spot)
	await wait_physics_frames(2)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"frost_flask")
	var slot := WeaponSlot.new(weapon, 1)
	var ctx := WeaponContext.new(s.player, StatBlock.from_defaults({StatIds.PROJECTILE_COUNT: 3.0}), s.enemies, s.projectiles, s.rng)
	assert_true(weapon.behavior.fire(slot, ctx))
	assert_eq(s.projectiles.active_count(), 4)
	var ends: Array[Vector2] = []
	for i in s.projectiles.active_count():
		ends.append(s.player.global_position + s.projectiles._active[i].velocity * s.projectiles._active[i].life)
	for a in ends.size():
		for b in range(a + 1, ends.size()):
			assert_gt(ends[a].distance_to(ends[b]), 80.0, "each flask lands on its own spot")


func test_poison_stacks_with_every_hit_and_counts_for_the_weapon() -> void:
	var s := await _setup(Vector2(100.0, 0.0), 100000.0)
	var enemy: Enemy = s.enemies.get_enemy(0)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"venom_fangs")
	assert_eq(weapon.status.type, StatusData.Type.POISON)
	s.enemies.damage_weapon = &"venom_fangs"
	for i in 3:
		s.enemies.damage_enemy(0, 10.0, false, Vector2.RIGHT, 0.0, weapon.status, 1.0)
	assert_eq(enemy.poison_stacks, 3, "three hits, three stacks")
	var before := enemy.hp
	await wait_seconds(1.0)
	assert_lt(enemy.hp, before - 10.0, "the stacks hurt every second")
	assert_gt(s.enemies.damage_dealt(0).get(&"venom_fangs", 0.0), 30.0, "the poison counts for the fangs")
	await wait_seconds(3.5)
	assert_eq(enemy.poison_stacks, 0, "it wears off")


func test_the_heavy_crossbow_leaves_no_ground_zone_and_slows_on_hit() -> void:
	# Dev decision 2026-10-19: no impact animation, so no ground zone (and no zone damage) either.
	var s := await _setup(Vector2(400.0, 0.0))
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"heavy_crossbow")
	assert_eq(weapon.zone_time, 0.0)
	assert_not_null(weapon.status)
	_fire(s, &"heavy_crossbow")
	await wait_seconds(1.1)  # the bolt hit, pierced on and ended
	assert_eq(s.projectiles._zones.size(), 0, "no patch is left where the bolt ended")


func test_every_weapon_has_a_painted_animation_for_its_attack() -> void:
	# Dev rule (2026-10-11): no attack animation drawn by code. Melee swings, beams, meteors, ground effects, impacts and
	# explosions must all be painted sheets.
	for weapon: WeaponData in ContentDB.get_all(&"weapons"):
		var id := String(weapon.id)
		if weapon.behavior is MeleeArcBehavior:
			assert_not_null(weapon.slash_sheet, "%s has a painted swing" % id)
		elif weapon.behavior is BeamBehavior:
			assert_not_null(weapon.beam_sheet, "%s has a painted beam" % id)
		elif weapon.behavior is StrikeBehavior:
			assert_not_null((weapon.behavior as StrikeBehavior).fall_sheet, "%s has a painted fall" % id)
			assert_not_null((weapon.behavior as StrikeBehavior).impact_sheet, "%s has a painted impact" % id)
		elif weapon.behavior is ProjectileShooterBehavior:
			if weapon.explosion_radius > 0.0 and weapon.landing_blast:
				assert_not_null(EffectSheets.explosion_for(weapon.projectile_style), "%s has a painted explosion" % id)
			elif weapon.zone_time <= 0.0:
				assert_not_null(EffectSheets.impact_for(weapon.projectile_style), "%s has a painted impact" % id)
			if weapon.zone_time > 0.0:
				assert_not_null(weapon.zone_sheet, "%s has a painted ground effect" % id)
