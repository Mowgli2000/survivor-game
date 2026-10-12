extends GutTest
## Shadow blades circle the hero and keep hurting what they touch; the arcane orb is a vortex that drags enemies in.


func _setup(enemy_at: Vector2, speed: float = 0.0) -> Dictionary:
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
	data.speed = speed
	data.radius = 12.0
	enemies.spawn(data, enemy_at)
	await wait_physics_frames(2)
	return {"player": player, "rng": rng, "vfx": vfx, "enemies": enemies, "projectiles": projectiles}


func _context(s: Dictionary) -> WeaponContext:
	return WeaponContext.new(s.player, StatBlock.from_defaults({}), s.enemies, s.projectiles, s.rng, s.vfx)


func test_shadow_blades_circle_the_hero_beyond_the_ring_of_weapons() -> void:
	var s := await _setup(Vector2(600.0, 0.0))
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"shadow_blades")
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), _context(s)))
	assert_eq(s.projectiles.active_count(), 2, "two blades at rank I")
	await wait_physics_frames(10)
	for i in s.projectiles.active_count():
		var distance: float = (s.projectiles.projectile_position(i) - s.player.global_position).length()
		assert_almost_eq(distance, weapon.attack_range, 1.0, "on its orbit, outside the ring of floating weapons")
		assert_gt(distance, MeleeArcBehavior.RING_GAP)


func test_a_blade_hurts_the_same_enemy_again_and_again() -> void:
	var s := await _setup(Vector2(150.0, 0.0))
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"shadow_blades")
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), _context(s)))
	await wait_seconds(0.8)
	var after_first: float = s.enemies.get_enemy(0).hp
	assert_lt(after_first, 5000.0, "a blade passed through it")
	await wait_seconds(1.2)
	assert_lt(s.enemies.get_enemy(0).hp, after_first, "the next pass hurts it again (a blade is not used up)")
	assert_gt(s.projectiles.active_count(), 0, "the blades are still turning")


func test_the_blades_never_run_out_and_end_with_their_weapon() -> void:
	var s := await _setup(Vector2(500.0, 0.0))
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"shadow_blades")
	var slot := WeaponSlot.new(weapon, 1)
	var ctx := _context(s)
	assert_true(weapon.behavior.fire(slot, ctx))
	assert_false(slot.quiet, "spawning them is worth a sound")
	await wait_seconds(5.0)
	assert_eq(s.projectiles.orbit_blades(slot).size(), 2, "still turning after a long time")
	assert_true(weapon.behavior.fire(slot, ctx))
	assert_true(slot.quiet, "upkeep makes no noise")
	assert_eq(s.projectiles.orbit_blades(slot).size(), 2, "upkeep keeps the same blades")
	var more := StatBlock.from_defaults({StatIds.PROJECTILE_COUNT: 1.0})
	var ctx_more := WeaponContext.new(s.player, more, s.enemies, s.projectiles, s.rng, s.vfx)
	weapon.behavior.fire(slot, ctx_more)
	assert_eq(s.projectiles.orbit_blades(slot).size(), 3, "the projectile stat adds a blade")
	slot.set_level(2)
	weapon.behavior.fire(slot, ctx_more)
	assert_eq(s.projectiles.orbit_blades(slot).size(), 3, "rank II adds none")
	slot.set_level(3)
	weapon.behavior.fire(slot, ctx_more)
	assert_eq(s.projectiles.orbit_blades(slot).size(), 4, "rank III adds a blade")
	slot.retired = true
	await wait_physics_frames(3)
	assert_eq(s.projectiles.active_count(), 0, "sold: the blades go with it")


func test_a_blade_hurts_along_its_whole_painted_length() -> void:
	var s := await _setup(Vector2(1000.0, 1000.0))
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"shadow_blades")
	assert_gt(weapon.hit_half_length, weapon.projectile_radius, "a blade is longer than it is wide")
	var blade := Projectile.new()
	blade.reset_basic(Vector2(300.0, 0.0), Vector2(0.0, 100.0), 10.0, 18.0, 10.0, Color.WHITE, 24)
	blade.half_length = 45.0
	blade.pierce_left = 100
	s.projectiles._active.append(blade)
	var data := EnemyData.new()
	data.max_hp = 500.0
	data.speed = 0.0
	data.radius = 10.0
	s.enemies.spawn(data, Vector2(300.0, 60.0))  # 60 px along the blade: out of reach of a plain 18 px circle, inside the capsule
	s.enemies.spawn(data, Vector2(300.0, 90.0))  # past the tip
	await wait_physics_frames(3)
	var near := 0
	for i in s.enemies.active_count():
		if s.enemies.get_enemy(i).hp < 500.0:
			near += 1
	assert_eq(near, 1, "only the one under the blade is hurt")


func test_shadow_blades_wait_for_an_enemy_and_stop_with_their_volley() -> void:
	var s := await _setup(Vector2(900.0, 900.0))
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"shadow_blades")
	assert_false(weapon.behavior.fire(WeaponSlot.new(weapon, 1), _context(s)), "nobody close: no blades")



func test_the_gravity_well_aims_at_the_thickest_bunch() -> void:
	var s := await _setup(Vector2(100.0, 0.0))  # the nearest enemy, alone
	var data := EnemyData.new()
	data.max_hp = 5000.0
	data.speed = 0.0
	data.radius = 10.0
	for i in 6:
		s.enemies.spawn(data, Vector2(-300.0, 20.0 * i))  # a bunch, farther away, on the other side
	await wait_physics_frames(2)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"pulse")
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), _context(s)))
	await wait_physics_frames(6)
	assert_lt(s.projectiles.projectile_position(0).x, s.player.global_position.x, "the vortex went for the bunch, not the nearest enemy")


func test_the_gravity_well_drags_enemies_to_its_center_and_the_landing_hurts_nothing() -> void:
	var s := await _setup(Vector2(300.0, 0.0))
	var data := EnemyData.new()
	data.max_hp = 5000.0
	data.speed = 0.0
	data.radius = 10.0
	s.enemies.spawn(data, Vector2(300.0, 60.0))
	s.enemies.spawn(data, Vector2(300.0, -60.0))
	await wait_physics_frames(2)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"pulse")
	assert_false(weapon.landing_blast, "the sphere hurts nothing by itself")
	assert_gt(weapon.zone_time, 0.0)
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), _context(s)))
	await wait_seconds(0.8)
	for i in s.enemies.active_count():
		assert_eq(s.enemies.get_enemy(i).hp, 5000.0, "just landed: no blast")
	await wait_seconds(2.0)
	var low := INF
	var high := -INF
	var hurt := 0
	for i in s.enemies.active_count():
		var enemy: Enemy = s.enemies.get_enemy(i)
		low = minf(low, enemy.position.y)
		high = maxf(high, enemy.position.y)
		if enemy.hp < 5000.0:
			hurt += 1
	assert_lt(high - low, 105.0, "dragged together (they started 120 px apart)")
	assert_gt(hurt, 0, "the well grinds what it holds")


func test_the_alchemical_cannon_blasts_each_enemy_it_passes_through() -> void:
	var s := await _setup(Vector2(200.0, 0.0))
	var data := EnemyData.new()
	data.max_hp = 5000.0
	data.speed = 0.0
	data.radius = 10.0
	s.enemies.spawn(data, Vector2(330.0, 0.0))
	s.enemies.spawn(data, Vector2(460.0, 0.0))
	await wait_physics_frames(2)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"alchemy_cannon")
	assert_true(weapon.blast_on_pierce)
	assert_true(weapon.behavior.fire(WeaponSlot.new(weapon, 1), _context(s)))
	await wait_seconds(0.45)
	assert_gt(s.projectiles.active_count(), 0, "the shell went through the first enemy")
	var hurt := 0
	for i in s.enemies.active_count():
		if s.enemies.get_enemy(i).hp < 5000.0:
			hurt += 1
	assert_eq(hurt, 2, "the enemies it passed through are blasted, the one ahead is not yet")
	await wait_seconds(1.0)
	for i in s.enemies.active_count():
		assert_lt(s.enemies.get_enemy(i).hp, 5000.0, "every enemy on the line got hurt")
	assert_eq(s.projectiles.active_count(), 0, "and the shell ended")
