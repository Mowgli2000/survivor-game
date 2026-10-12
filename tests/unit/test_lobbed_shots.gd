extends GutTest
## Bombs, flasks and grenades are lobbed: spinning in an arc, they explode once, where they land
## (playtest 2026-10-10: the blast used to play every frame from the launch).


func _setup() -> Dictionary:
	var arena := Rect2(-1000, -1000, 2000, 2000)
	var player := Player.new()
	player.setup(CharacterData.new(), arena)
	player.invincible = true
	player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(player)
	var rng := RandomNumberGenerator.new()
	var vfx := Vfx.new()
	add_child_autofree(vfx)
	var enemies := EnemyManager.new()
	enemies.setup(Party.solo(player), arena, 4, rng, vfx, null)
	add_child_autofree(enemies)
	var projectiles := ProjectileManager.new()
	add_child_autofree(projectiles)
	projectiles.setup(enemies, arena, 4, vfx)
	var data := EnemyData.new()
	data.max_hp = 5000.0
	data.speed = 0.0
	data.radius = 10.0
	enemies.spawn(data, Vector2(380.0, 0.0))
	await wait_physics_frames(2)
	return {"player": player, "rng": rng, "vfx": vfx, "enemies": enemies, "projectiles": projectiles}


func test_a_flask_explodes_only_when_it_lands() -> void:
	var s := await _setup()
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"fire_flask")
	var ctx := WeaponContext.new(s.player, StatBlock.from_defaults({}), s.enemies, s.projectiles, s.rng)
	ctx.vfx = s.vfx
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), ctx))
	await wait_seconds(0.25)
	assert_eq(s.projectiles.active_count(), 1, "still in the air")
	assert_eq(s.vfx.active_count(), 0, "no blast and no ring while it flies")
	assert_eq(s.enemies.get_enemy(0).hp, 5000.0, "nothing is hurt while it flies")
	await wait_seconds(1.2)
	assert_eq(s.projectiles.active_count(), 0, "it landed")
	assert_lt(s.enemies.get_enemy(0).hp, 5000.0, "the blast hurts where it landed")


func test_a_meteor_hurts_only_when_it_lands() -> void:
	var s := await _setup()
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"meteor_grimoire")
	var ctx := WeaponContext.new(s.player, StatBlock.from_defaults({}), s.enemies, s.projectiles, s.rng)
	ctx.vfx = s.vfx
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), ctx))
	await wait_seconds((weapon.behavior as StrikeBehavior).fall_sheet.duration * 0.3)  # the fall is very short (ADR 0030)
	var rock_y := INF
	for i in s.vfx.active_count():
		rock_y = minf(rock_y, s.vfx._a[i].y)
	assert_lt(rock_y, s.enemies.get_enemy(0).position.y - 200.0, "the rock comes from the top of the screen, not from below")
	assert_eq(s.enemies.get_enemy(0).hp, 5000.0, "the rock is still falling: nothing is hurt")
	assert_gt(s.vfx.active_count(), 0, "the painted rock is falling")
	await wait_seconds(0.6)
	assert_lt(s.enemies.get_enemy(0).hp, 5000.0, "it hurts where it landed")


func test_painted_beams_and_meteor_art_exist() -> void:
	var laser: WeaponData = ContentDB.get_def(&"weapons", &"laser_pistol")
	assert_not_null(laser.beam_sheet, "the crystal wand has a painted beam")
	var frost: WeaponData = ContentDB.get_def(&"weapons", &"frost_scepter")
	assert_not_null(frost.slash_sheet, "the frost scepter has a painted cone")
	var meteor: StrikeBehavior = (ContentDB.get_def(&"weapons", &"meteor_grimoire") as WeaponData).behavior
	assert_not_null(meteor.fall_sheet)
	assert_not_null(meteor.impact_sheet)


func test_a_frag_grenade_throws_one_shot_that_bursts_into_shards() -> void:
	var s := await _setup()
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"frag_grenade")
	var ctx := WeaponContext.new(s.player, StatBlock.from_defaults({}), s.enemies, s.projectiles, s.rng)
	ctx.vfx = s.vfx
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), ctx))
	assert_eq(s.projectiles.active_count(), 1, "one grenade, not three")
	var most := 0
	for i in 60:
		await wait_physics_frames(4)
		most = maxi(most, s.projectiles.active_count())
	assert_gte(most, weapon.fragments, "the blast threw its shards")


func test_the_cannon_ball_flies_straight() -> void:
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"alchemy_cannon")
	assert_false(weapon.projectile_style in ProjectileShooterBehavior.LOBBED, "not lobbed")


func test_zone_bonus_is_halved_above_the_base() -> void:
	assert_eq(CombatMath.area_scale(0.5), 0.5, "a malus counts in full")
	assert_eq(CombatMath.area_scale(1.0), 1.0)
	assert_eq(CombatMath.area_scale(2.0), 1.5, "+100 % Zone = x1.5")
	assert_eq(CombatMath.area_scale(3.0), 2.0, "+200 % Zone = x2")


func test_the_bomb_burns_its_fuse_on_the_ground_before_it_explodes() -> void:
	var s := await _setup()
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"bomb")
	var ctx := WeaponContext.new(s.player, StatBlock.from_defaults({}), s.enemies, s.projectiles, s.rng)
	ctx.vfx = s.vfx
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), ctx))
	var landed := false
	for i in 100:
		await wait_physics_frames(2)
		if s.projectiles.active_count() == 1 and s.projectiles.is_fused(0):
			landed = true
			break
	assert_true(landed, "it landed and sits there")
	assert_eq(s.enemies.get_enemy(0).hp, 5000.0, "nothing is hurt while the fuse burns")
	await wait_seconds(weapon.fuse_time + 0.3)
	assert_lt(s.enemies.get_enemy(0).hp, 5000.0, "then it explodes")


func test_the_explosive_flask_bounces_to_another_enemy() -> void:
	var s := await _setup()
	var far: Enemy = s.enemies.spawn(_far_data(), Vector2(380.0, 230.0))
	await wait_physics_frames(2)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"bazooka")
	var ctx := WeaponContext.new(s.player, StatBlock.from_defaults({}), s.enemies, s.projectiles, s.rng)
	ctx.vfx = s.vfx
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), ctx))
	await wait_seconds(2.0)
	assert_lt(far.hp, 5000.0, "the second blast reached the enemy outside the first one")


func _far_data() -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = 5000.0
	data.speed = 0.0
	data.radius = 10.0
	return data


func test_the_fire_flask_leaves_burning_ground() -> void:
	var s := await _setup()
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"fire_flask")
	var ctx := WeaponContext.new(s.player, StatBlock.from_defaults({}), s.enemies, s.projectiles, s.rng)
	ctx.vfx = s.vfx
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), ctx))
	await wait_seconds(1.3)  # landed
	var after_blast: float = s.enemies.get_enemy(0).hp
	await wait_seconds(1.5)
	assert_lt(s.enemies.get_enemy(0).hp, after_blast, "the ground keeps burning")


func test_a_volley_of_meteors_spreads_over_different_bunches() -> void:
	var s := await _setup()
	var data := EnemyData.new()
	data.max_hp = 5000.0
	data.speed = 0.0
	data.radius = 10.0
	for spot in [Vector2(-300.0, 150.0), Vector2(60.0, -330.0), Vector2(200.0, 330.0), Vector2(-120.0, -120.0)]:
		s.enemies.spawn(data, spot)
	await wait_physics_frames(2)
	s.rng.seed = 5  # the meteors pick their targets at random: a fixed draw keeps the test stable
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"meteor_grimoire")
	var ctx := WeaponContext.new(s.player, StatBlock.from_defaults({StatIds.PROJECTILE_COUNT: 2.0}), s.enemies, s.projectiles, s.rng)
	ctx.vfx = s.vfx
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), ctx))
	var points: Array[Vector2] = []
	for i in s.vfx.active_count():
		points.append(s.vfx._a[i] + Vector2(0.0, -StrikeBehavior.FALL_FROM.y))  # the rock starts straight above its impact
	assert_eq(points.size(), 3, "three meteors")
	for a in points.size():
		for b in range(a + 1, points.size()):
			assert_gt(points[a].distance_to(points[b]), 120.0, "each meteor lands on another bunch")
