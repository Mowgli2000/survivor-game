extends GutTest
## EnemyManager (damage API, statuses, ranged enemies) and the projectile
## managers working together, without the full run.

var _player: Player
var _enemies: EnemyManager
var _projectiles: ProjectileManager
var _enemy_shots: EnemyProjectileManager
var _data: EnemyData


func before_each() -> void:
	var arena := Rect2(-1000, -1000, 2000, 2000)
	_player = Player.new()
	_player.setup(CharacterData.new(), arena)
	_player.invincible = true
	_player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(_player)
	_enemy_shots = EnemyProjectileManager.new()
	_enemy_shots.setup(Party.solo(_player), arena)
	add_child_autofree(_enemy_shots)
	_enemies = EnemyManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	_enemies.setup(Party.solo(_player), arena, 4, rng, null, _enemy_shots)
	add_child_autofree(_enemies)
	_projectiles = ProjectileManager.new()
	_projectiles.setup(_enemies, arena, 4)
	add_child_autofree(_projectiles)
	_data = _enemy_data(10.0, 0.0)


func _enemy_data(hp: float, speed: float) -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = hp
	data.speed = speed
	data.radius = 16.0
	return data


func _status(type: StatusData.Type, power: float, duration: float) -> StatusData:
	var status := StatusData.new()
	status.type = type
	status.power = power
	status.duration = duration
	return status


func _weapon(setup: Callable) -> WeaponStats:
	var data := WeaponData.new()
	data.projectile_radius = 6.0
	data.projectile_lifetime = 2.0
	setup.call(data)
	return WeaponStats.compute(data, 1)


func test_damage_kills_and_emits() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_data, Vector2(500, 0))
	_enemies.damage_enemy(0, 4.0, false, Vector2.RIGHT, 0.0)
	assert_eq(_enemies.get_enemy(0).hp, 6.0)
	_enemies.damage_enemy(0, 10.0, true, Vector2.RIGHT, 0.0)
	assert_signal_emit_count(_enemies, "enemy_killed", 1)
	_enemies.damage_enemy(0, 10.0, false, Vector2.RIGHT, 0.0)
	assert_signal_emit_count(_enemies, "enemy_killed", 1, "dead enemy cannot die twice")


func test_dead_enemies_are_recycled() -> void:
	_enemies.spawn(_data, Vector2(500, 0))
	_enemies.spawn(_data, Vector2(-500, 0))
	_enemies.damage_enemy(0, 100.0, false, Vector2.ZERO, 0.0)
	await wait_physics_frames(2)
	assert_eq(_enemies.active_count(), 1)
	assert_eq(_enemies.get_enemy(0).position, Vector2(-500, 0))


func test_find_nearest_after_grid_rebuild() -> void:
	_enemies.spawn(_data, Vector2(300, 0))
	_enemies.spawn(_data, Vector2(100, 0))
	await wait_physics_frames(1)
	var index := _enemies.find_nearest(Vector2.ZERO, 1000.0)
	assert_almost_eq(_enemies.get_enemy(index).position.x, 100.0, 1.0)
	assert_eq(_enemies.find_nearest(Vector2.ZERO, 50.0), -1)


func test_arc_only_hits_enemies_in_front() -> void:
	_enemies.spawn(_data, Vector2(100, 0))   # in front
	_enemies.spawn(_data, Vector2(-100, 0))  # behind
	_enemies.spawn(_data, Vector2(400, 0))   # too far
	await wait_physics_frames(1)
	var hits := _enemies.damage_in_radius(Vector2.ZERO, 150.0, 1.0, false, 0.0, null, 1.0,
		Vector2.RIGHT, cos(deg_to_rad(60.0)))
	assert_eq(hits, 1)


func test_segment_hits_enemies_along_the_line() -> void:
	_enemies.spawn(_data, Vector2(100, 5))
	_enemies.spawn(_data, Vector2(300, -10))
	_enemies.spawn(_data, Vector2(200, 200))  # off the line
	await wait_physics_frames(1)
	var hits := _enemies.damage_along_segment(Vector2.ZERO, Vector2(600, 0), 5.0, 1.0, false, 0.0)
	assert_eq(hits, 2)


func test_burn_deals_damage_over_time_and_can_kill() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_enemy_data(10.0, 0.0), Vector2(500, 0))
	# 1 damage hit, burn = 1 x 5.0 = 5 dps for 3 s -> dies after ~2 s.
	_enemies.damage_enemy(0, 1.0, false, Vector2.ZERO, 0.0, _status(StatusData.Type.BURN, 5.0, 3.0))
	assert_gt(_enemies.get_enemy(0).burn_time, 0.0)
	await wait_physics_frames(150)
	assert_signal_emit_count(_enemies, "enemy_killed", 1)


func test_slow_reduces_speed_then_expires() -> void:
	_enemies.spawn(_enemy_data(100.0, 100.0), Vector2(600, 0))
	_enemies.damage_enemy(0, 1.0, false, Vector2.ZERO, 0.0, _status(StatusData.Type.SLOW, 0.5, 0.5))
	var start := _enemies.get_enemy(0).position.x
	await wait_physics_frames(15)  # 0.25 s at half speed -> ~12.5 px
	var travelled := start - _enemies.get_enemy(0).position.x
	assert_almost_eq(travelled, 12.5, 4.0)
	await wait_physics_frames(30)
	assert_eq(_enemies.get_enemy(0).slow_time, 0.0)


func test_shock_chains_to_nearby_enemies() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(300, 0))
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(400, 0))
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(500, 0))
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(900, 0))  # out of chain range
	await wait_physics_frames(1)
	var shock := _status(StatusData.Type.SHOCK, 0.5, 0.0)
	shock.chain_count = 3
	shock.chain_range = 150.0
	_enemies.damage_enemy(0, 10.0, false, Vector2.ZERO, 0.0, shock)
	assert_signal_emit_count(_enemies, "enemy_damaged", 3, "first hit + 2 jumps")
	assert_eq(_enemies.get_enemy(2).hp, 95.0)
	assert_eq(_enemies.get_enemy(3).hp, 100.0)


func test_projectile_hits_and_pierce() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_data, Vector2(200, 0))
	_enemies.spawn(_data, Vector2(300, 0))
	await wait_physics_frames(1)
	_projectiles.spawn(Vector2(150, 0), Vector2(600, 0), 3.0, false, 1, 0.0, 1.0, _weapon(func(_d: WeaponData) -> void: pass))
	await wait_physics_frames(30)
	assert_signal_emit_count(_enemies, "enemy_damaged", 2)
	assert_eq(_projectiles.active_count(), 0)


func test_projectile_bounces_to_another_enemy() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(200, 0))
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(200, 150))  # not in the initial line
	await wait_physics_frames(1)
	var weapon := _weapon(func(d: WeaponData) -> void:
		d.bounces = 1
		d.bounce_range = 300.0)
	_projectiles.spawn(Vector2(100, 0), Vector2(600, 0), 3.0, false, 0, 0.0, 1.0, weapon)
	await wait_physics_frames(40)
	assert_signal_emit_count(_enemies, "enemy_damaged", 2)


func test_explosion_damages_the_area() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(200, 0))
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(240, 60))
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(600, 600))  # far away
	await wait_physics_frames(1)
	var weapon := _weapon(func(d: WeaponData) -> void: d.explosion_radius = 100.0)
	_projectiles.spawn(Vector2(100, 0), Vector2(600, 0), 5.0, false, 0, 0.0, 1.0, weapon)
	await wait_physics_frames(20)
	assert_signal_emit_count(_enemies, "enemy_damaged", 2)
	assert_eq(_projectiles.active_count(), 0)


func test_ranged_enemy_keeps_distance_and_shoots() -> void:
	var data := _enemy_data(10.0, 200.0)
	data.movement = EnemyData.Movement.RANGED
	data.preferred_distance = 300.0
	data.fire_cooldown = 0.2
	data.projectile_damage = 7.0
	data.projectile_speed = 900.0
	_player.invincible = false
	_enemies.spawn(data, Vector2(120, 0))  # too close: should back off
	await wait_physics_frames(60)
	assert_gt(_enemies.get_enemy(0).position.length(), 200.0, "ranged enemy backed off")
	assert_lt(_player.hp, 100.0, "its shots hit the player")


func test_an_elite_is_never_drawn_bigger_than_the_smallest_boss() -> void:
	_enemies.elite_scale = 1.6
	var tank: EnemyData = ContentDB.get_def(&"enemies", &"tank")
	var boss: EnemyData = ContentDB.get_def(&"enemies", &"ronin")
	var elite_height := tank.radius * _enemies.elite_factor(tank) * Enemy.SPRITE_HEIGHT_PER_RADIUS * tank.sprite_scale
	var boss_height := boss.radius * Enemy.SPRITE_HEIGHT_PER_RADIUS * boss.sprite_scale
	assert_lte(elite_height, EnemyManager.ELITE_MAX_HEIGHT + 0.01, "elite tank held under the cap")
	assert_lt(elite_height, boss_height, "a boss is bigger than an elite tank")
	var runner: EnemyData = ContentDB.get_def(&"enemies", &"runner")
	assert_almost_eq(_enemies.elite_factor(runner), 1.6, 0.001, "small elites keep the stage scale")


func test_elite_has_more_radius_and_flag() -> void:
	_enemies.elite_scale = 1.5
	var elite := _enemies.spawn(_data, Vector2(300, 0), 5.0, true)
	assert_true(elite.elite)
	assert_almost_eq(elite.radius, 24.0, 0.001)
	assert_almost_eq(elite.max_hp, 50.0, 0.001)


func test_elite_kill_reports_elite() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_data, Vector2(300, 0), 1.0, true)
	_enemies.damage_enemy(0, 1000.0, false, Vector2.RIGHT, 0.0)
	assert_signal_emitted_with_parameters(_enemies, "enemy_killed", [_data, Vector2(300, 0), true])


func test_clear_all_removes_enemies_without_kills() -> void:
	watch_signals(_enemies)
	for i in 5:
		_enemies.spawn(_data, Vector2(200 + i * 40, 0))
	_enemies.clear_all()
	assert_eq(_enemies.active_count(), 0)
	assert_signal_not_emitted(_enemies, "enemy_killed")


func test_pooled_elite_resets_to_normal() -> void:
	_enemies.spawn(_data, Vector2(300, 0), 1.0, true)
	_enemies.clear_all()
	var normal := _enemies.spawn(_data, Vector2(300, 0))
	assert_false(normal.elite)
	assert_almost_eq(normal.radius, _data.radius, 0.001)


func test_enemy_projectiles_clear_all() -> void:
	_enemy_shots.spawn(Vector2(500, 0), Vector2.LEFT * 10.0, 5.0, 8.0)
	_enemy_shots.spawn(Vector2(-500, 0), Vector2.RIGHT * 10.0, 5.0, 8.0)
	_enemy_shots.clear_all()
	assert_eq(_enemy_shots.active_count(), 0)


## Regression: the range stat let weapons aim farther than their projectiles fly,
## so rockets exploded in empty space before reaching the target.
func test_range_stat_extends_projectile_flight() -> void:
	watch_signals(_enemies)
	var target := _enemy_data(1000.0, 0.0)
	_enemies.spawn(target, Vector2(350, 0))
	await wait_physics_frames(1)
	var stats := StatBlock.from_defaults()
	var bonus := StatModifier.new()
	bonus.stat = StatIds.RANGE
	bonus.percent = 1.0  # x2: aims up to 800 px
	stats.add_modifier(bonus)
	var data := WeaponData.new()
	data.behavior = ProjectileShooterBehavior.new()
	data.attack_range = 400.0
	data.projectile_speed = 400.0
	data.projectile_lifetime = 0.5  # 200 px of flight without the range bonus
	data.explosion_radius = 40.0
	var ctx := WeaponContext.new(_player, stats, _enemies, _projectiles, RandomNumberGenerator.new())
	assert_true(data.behavior.fire(WeaponSlot.new(data), ctx))
	await wait_physics_frames(60)
	assert_signal_emitted(_enemies, "enemy_damaged", "the rocket reaches the enemy it aimed at")


func test_enemy_without_sprite_uses_placeholder() -> void:
	var enemy := _enemies.spawn(_data, Vector2(300, 0))
	assert_null(enemy.animator.sheet)
	await wait_physics_frames(2)
	assert_true(enemy.is_alive())


func test_enemy_sprite_animates_and_faces_player() -> void:
	var data := _enemy_data(10.0, 50.0)
	data.sprite_id = &"grunt"
	var enemy := _enemies.spawn(data, Vector2(300, 0))
	assert_not_null(enemy.animator.sheet)
	var start := enemy.animator.time
	await wait_physics_frames(3)
	assert_gt(enemy.animator.time, start)
	assert_eq(enemy.animator.facing, -1.0, "player is on the left")


func test_elite_falls_back_to_normal_sheet() -> void:
	var data := _enemy_data(10.0, 0.0)
	data.sprite_id = &"drifter"  # has no _elite sheet
	assert_not_null(data.get_sheet(false))
	assert_eq(data.get_sheet(true), data.get_sheet(false))


func test_recycled_enemy_switches_sheet() -> void:
	var a := _enemy_data(1.0, 0.0)
	a.sprite_id = &"grunt"
	var b := _enemy_data(1.0, 0.0)
	b.sprite_id = &"tank"
	var enemy := _enemies.spawn(a, Vector2(300, 0))
	_enemies.damage_enemy(_enemies._active.find(enemy), 10.0, false, Vector2.RIGHT, 0.0)
	await wait_physics_frames(1)
	var again := _enemies.spawn(b, Vector2(300, 0))
	assert_eq(again.animator.sheet, b.get_sheet(false))
	assert_true(again.animator.sheet.animations.has(&"walk"))


func test_projectiles_start_at_the_weapon_muzzle() -> void:
	_enemies.spawn(_data, Vector2(300, 0))
	await wait_physics_frames(1)
	var data: WeaponData = ContentDB.get_def(&"weapons", &"pulse")
	var slot := WeaponSlot.new(data)
	slot.mount_offset = Vector2(0, -30)
	var ctx := WeaponContext.new(_player, StatBlock.from_defaults({}), _enemies, _projectiles,
		RandomNumberGenerator.new())
	assert_true(data.behavior.fire(slot, ctx))
	var expected := ctx.muzzle(slot, (Vector2(300, 0) - Vector2(0, -30)).normalized())
	assert_almost_eq(_projectiles.projectile_position(0), expected, Vector2.ONE * 0.5)
	assert_ne(expected, _player.global_position)


func test_holder_emits_weapon_fired() -> void:
	_enemies.spawn(_data, Vector2(100, 0))
	await wait_physics_frames(1)
	var holder := WeaponHolder.new()
	add_child_autofree(holder)
	holder.setup(WeaponContext.new(_player, StatBlock.from_defaults({}), _enemies, _projectiles,
		RandomNumberGenerator.new()))
	holder.add_weapon(ContentDB.get_def(&"weapons", &"pulse"))
	watch_signals(holder)
	await wait_physics_frames(2)
	assert_signal_emitted_with_parameters(holder, "weapon_fired", [0])


func test_beam_from_far_mount_still_reaches_a_target_at_max_range() -> void:
	var laser: WeaponData = ContentDB.get_def(&"weapons", &"laser_pistol")
	var target := Vector2(laser.attack_range - 1.0, 0)
	var small := _enemy_data(1000.0, 0.0)
	small.radius = 3.0
	_enemies.spawn(small, target)
	await wait_physics_frames(1)
	var slot := WeaponSlot.new(laser)
	slot.mount_offset = Vector2(-50, 0)  # mount on the far side
	var ctx := WeaponContext.new(_player, StatBlock.from_defaults({}), _enemies, _projectiles,
		RandomNumberGenerator.new())
	watch_signals(_enemies)
	assert_true(laser.behavior.fire(slot, ctx))
	assert_signal_emitted(_enemies, "enemy_damaged", "the beam reaches its target")


func test_point_blank_projectile_hits_the_target() -> void:
	var pulse: WeaponData = ContentDB.get_def(&"weapons", &"pulse")
	var slot := WeaponSlot.new(pulse)
	slot.mount_offset = Vector2(50, -24)
	_enemies.spawn(_enemy_data(1000.0, 0.0), Vector2(58, -24))  # right on the mount
	await wait_physics_frames(1)
	var ctx := WeaponContext.new(_player, StatBlock.from_defaults({}), _enemies, _projectiles,
		RandomNumberGenerator.new())
	watch_signals(_enemies)
	assert_true(pulse.behavior.fire(slot, ctx))
	await wait_physics_frames(3)
	assert_signal_emitted(_enemies, "enemy_damaged", "a shot at point blank is not spawned past its target")


func test_no_stale_target_after_clear_all() -> void:
	for i in 5:
		_enemies.spawn(_data, Vector2(100 + i * 40, 0))
	await wait_physics_frames(1)
	_enemies.clear_all()
	# Queried before the next physics step (e.g. the first frame after the shop).
	assert_eq(_enemies.find_nearest(Vector2.ZERO, 1000.0), -1, "cleared enemies are not targets")


func test_contact_damage_scales_with_the_wave_multiplier() -> void:
	_player.invincible = false
	var data := _enemy_data(10.0, 0.0)
	data.contact_damage = 10.0
	_enemies.spawn(data, Vector2.ZERO, 1.0, false, 2.0)
	var hp_before := _player.hp
	await wait_physics_frames(2)
	assert_almost_eq(hp_before - _player.hp, 20.0, 0.01, "10 contact damage x 2")


## Bazooka missiles: homing turns them toward an enemy off their straight line.
func test_homing_projectile_turns_toward_the_enemy() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_data, Vector2(300, 200))
	await wait_physics_frames(1)
	_projectiles.spawn(Vector2(0, 0), Vector2(300, 0), 3.0, false, 0, 0.0, 1.0,
		_weapon(func(d: WeaponData) -> void: d.homing = 6.0))
	await wait_physics_frames(90)
	assert_signal_emitted(_enemies, "enemy_damaged", "a straight shot would have missed")


func test_straight_projectile_misses_the_same_enemy() -> void:
	watch_signals(_enemies)
	_enemies.spawn(_data, Vector2(300, 200))
	await wait_physics_frames(1)
	_projectiles.spawn(Vector2(0, 0), Vector2(300, 0), 3.0, false, 0, 0.0, 1.0, _weapon(func(_d: WeaponData) -> void: pass))
	await wait_physics_frames(90)
	assert_signal_not_emitted(_enemies, "enemy_damaged")


func _strike(area: float, count: int) -> WeaponData:
	var data := WeaponData.new()
	data.behavior = StrikeBehavior.new()
	data.base_damage = 20.0
	data.attack_range = 500.0
	data.area = area
	data.projectile_count = count
	return data


func test_strike_hits_every_enemy_in_its_area() -> void:
	var a := _enemies.spawn(_enemy_data(100.0, 0.0), Vector2(300, 0))
	var b := _enemies.spawn(_enemy_data(100.0, 0.0), Vector2(330, 0))
	var far := _enemies.spawn(_enemy_data(100.0, 0.0), Vector2(300, 600))  # out of range: never picked
	await wait_physics_frames(1)
	var ctx := WeaponContext.new(_player, StatBlock.from_defaults({}), _enemies, _projectiles,
		RandomNumberGenerator.new())
	assert_true(_strike(60.0, 1).behavior.fire(WeaponSlot.new(_strike(60.0, 1)), ctx))
	assert_lt(a.hp, 100.0, "the nearest enemy is struck")
	assert_lt(b.hp, 100.0, "its neighbour too")
	assert_eq(far.hp, 100.0, "outside the area")


func test_strike_needs_an_enemy_in_range_and_is_ranged() -> void:
	_enemies.spawn(_enemy_data(100.0, 0.0), Vector2(900, 0))
	await wait_physics_frames(1)
	var data := _strike(60.0, 3)
	var ctx := WeaponContext.new(_player, StatBlock.from_defaults({}), _enemies, _projectiles,
		RandomNumberGenerator.new())
	assert_false(data.behavior.fire(WeaponSlot.new(data), ctx))
	assert_false(data.is_melee())


func test_area_target_cap_grows_with_the_zone_stat() -> void:
	for i in 40:
		_enemies.spawn(_data, Vector2(i % 8 * 10.0, i / 8 * 10.0))
	await wait_physics_frames(1)
	_enemies.area_max_targets = 20
	_enemies.damage_source = 0
	assert_eq(_enemies.damage_in_radius(Vector2.ZERO, 300.0, 0.0, false, 0.0), 20, "base cap")
	_enemies.set_area_target_scale(0, 1.5)
	assert_eq(_enemies.area_targets_for(0), 30, "+50 % Zone: 30 targets")
	assert_eq(_enemies.damage_in_radius(Vector2.ZERO, 300.0, 0.0, false, 0.0), 30)
	_enemies.set_area_target_scale(0, 0.8)
	assert_eq(_enemies.area_targets_for(0), 20, "less Zone never lowers the cap")
	assert_eq(_enemies.area_targets_for(1), 20, "other players keep their own cap")


func test_damage_dealt_is_recorded_per_weapon_and_player() -> void:
	_enemies.spawn(_data, Vector2(100, 0))
	_enemies.spawn(_data, Vector2(-100, 0))
	await wait_physics_frames(1)
	_enemies.damage_source = 0
	_enemies.damage_weapon = &"katana"
	_enemies.damage_enemy(0, 4.0, false, Vector2.ZERO, 0.0)
	_enemies.damage_weapon = &"bomb"
	_enemies.damage_enemy(1, 25.0, false, Vector2.ZERO, 0.0)
	var dealt := _enemies.damage_dealt(0)
	assert_almost_eq(dealt[&"katana"], 4.0, 0.01)
	assert_almost_eq(dealt[&"bomb"], 10.0, 0.01, "only the HP the enemy had (overkill not counted)")
	assert_eq(_enemies.damage_dealt(1), {}, "player 2 dealt nothing")


func test_capped_area_hit_still_reaches_the_boss() -> void:
	# Simulator: bosses hidden in their horde were left out of capped area hits.
	var boss := _enemy_data(1000.0, 0.0)
	boss.boss = true
	for i in 30:
		_enemies.spawn(_data, Vector2(i % 6 * 8.0, i / 6 * 8.0))
	_enemies.spawn(boss, Vector2(20, 20))
	await wait_physics_frames(1)
	_enemies.area_max_targets = 20
	var hits := _enemies.damage_in_radius(Vector2.ZERO, 300.0, 5.0, false, 0.0)
	assert_eq(hits, 21, "20 regular enemies + the boss")
	var boss_index := -1
	for i in _enemies.active_count():
		if _enemies.get_enemy(i).data == boss:
			boss_index = i
	assert_lt(_enemies.get_enemy(boss_index).hp, 1000.0, "the boss was hit")
