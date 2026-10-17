extends GutTest
## The Demon Knight's own attacks (danger 1 final boss): who is hurt, who is spared.

var _player: Player
var _enemies: EnemyManager
var _ctx: BossContext
var _boss: Enemy


func before_each() -> void:
	var arena := Rect2(-1000, -1000, 2000, 2000)
	_player = Player.new()
	_player.setup(CharacterData.new(), arena)
	_player.invincible = false
	_player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(_player)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var shots := EnemyProjectileManager.new()
	shots.setup(Party.solo(_player), arena)
	add_child_autofree(shots)
	_enemies = EnemyManager.new()
	_enemies.setup(Party.solo(_player), arena, 4, rng, null, shots)
	add_child_autofree(_enemies)
	_ctx = BossContext.new()
	_ctx.party = Party.solo(_player)
	_ctx.enemies = _enemies
	_ctx.enemy_projectiles = shots
	_ctx.rng = rng
	_boss = _enemies.spawn(ContentDB.get_def(&"enemies", &"shogun"), Vector2(400, 0))


func _hp_lost() -> float:
	return _player.stats.get_value(StatIds.MAX_HP) - _player.hp


func test_the_knight_kit_is_valid_and_has_its_own_attacks() -> void:
	var shogun: EnemyData = ContentDB.get_def(&"enemies", &"shogun")
	var kinds := {}
	for phase in shogun.phases:
		for pattern in phase.patterns:
			assert_eq(pattern.validate(), "", "pattern valid")
			kinds[pattern.get_script().get_global_name()] = true
	for name in [&"CrossSlashPattern", &"ShadowStepPattern", &"BladeRainPattern", &"ThrustBarragePattern", &"FlameRingPattern", &"IaidoPattern"]:
		assert_true(kinds.has(name), "%s is in the kit" % name)
	assert_false(kinds.has(&"AimedFanPattern"), "no fan: it belongs to other bosses")
	assert_false(kinds.has(&"RadialBurstPattern"), "no ring of shots: it belongs to other bosses")


func test_the_cross_hurts_a_player_on_a_line_and_spares_one_beside_it() -> void:
	var pattern := CrossSlashPattern.new()
	_player.global_position = Vector2.ZERO
	pattern.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_gt(_hp_lost(), 0.0, "standing at the crossing hurts")
	_player.hp = _player.stats.get_value(StatIds.MAX_HP)
	# Between the two lines (they are diagonals from the boss's direction): well off both.
	var base := (Vector2.ZERO - _boss.position).angle()
	_player.global_position = Vector2.from_angle(base) * 300.0
	pattern.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_eq(_hp_lost(), 0.0, "between the arms is safe")


func test_the_shadow_step_brings_the_boss_next_to_the_player_then_strikes() -> void:
	var pattern := ShadowStepPattern.new()
	pattern.repeats = 2
	_player.global_position = Vector2(-200, 0)
	pattern.fire(_ctx, _boss, _player.global_position, 0)
	assert_almost_eq(_boss.position.distance_to(_player.global_position), pattern.landing_distance, 1.0)
	assert_eq(_hp_lost(), 0.0, "the jump itself does not hurt")
	pattern.fire(_ctx, _boss, _player.global_position, 1)
	assert_gt(_hp_lost(), 0.0, "the arc catches a player who stayed")


func test_the_shadow_step_arc_misses_a_player_who_stepped_back() -> void:
	var pattern := ShadowStepPattern.new()
	pattern.repeats = 2
	_player.global_position = Vector2(-200, 0)
	pattern.fire(_ctx, _boss, _player.global_position, 0)
	_player.global_position = _boss.position + Vector2(-pattern.arc_radius - 80.0, 0.0)
	pattern.fire(_ctx, _boss, _player.global_position, 1)
	assert_eq(_hp_lost(), 0.0)


func test_the_blade_rain_leaves_one_lane_and_it_moves() -> void:
	var pattern := BladeRainPattern.new()
	var aim := Vector2(10, 0)
	assert_ne(pattern.lane(aim, 0), pattern.strips / 2, "volley 0: the free lane is not the one under the aim")
	assert_eq(absi(pattern.lane(aim, 0) - pattern.strips / 2), BladeRainPattern.LANE_OFFSET, "a few strips away")
	assert_ne(pattern.lane(aim, 1), pattern.lane(aim, 0), "the lane slides each volley")
	_player.global_position = Vector2(pattern.strip_x(aim, pattern.lane(aim, 0)), 0.0)
	pattern.fire(_ctx, _boss, aim, 0)
	assert_eq(_hp_lost(), 0.0, "in the free lane: safe")
	_player.global_position = Vector2(pattern.strip_x(aim, pattern.lane(aim, 0) + 2), 0.0)
	pattern.fire(_ctx, _boss, aim, 0)
	assert_gt(_hp_lost(), 0.0, "in another strip: hurt")


func test_the_thrust_barrage_aims_then_lunges_towards_the_target() -> void:
	var pattern := ThrustBarragePattern.new()
	pattern.repeats = 6
	assert_eq(pattern.validate(), "")
	pattern.repeats = 5
	assert_ne(pattern.validate(), "", "odd volleys are refused")
	pattern.repeats = 6
	pattern.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_eq(_boss.forced_velocity, Vector2.ZERO, "stops to aim")
	pattern.fire(_ctx, _boss, Vector2.ZERO, 1)
	assert_lt(_boss.forced_velocity.x, 0.0, "then lunges towards the aim (to the left of the boss)")


func test_the_flame_ring_burns_the_band_but_not_its_opening() -> void:
	var pattern := FlameRingPattern.new()
	var aim := Vector2.ZERO
	var gap := pattern.gap_angle(_boss, aim, 0)
	_player.global_position = aim + Vector2.from_angle(gap + PI) * pattern.start_radius
	pattern.fire(_ctx, _boss, aim, 0)
	assert_gt(_hp_lost(), 0.0, "on the band, away from the opening")
	_player.hp = _player.stats.get_value(StatIds.MAX_HP)
	_player.global_position = aim + Vector2.from_angle(gap) * pattern.start_radius
	pattern.fire(_ctx, _boss, aim, 0)
	assert_eq(_hp_lost(), 0.0, "in the opening")


func test_the_iaido_hurts_in_front_and_spares_behind() -> void:
	var pattern := IaidoPattern.new()
	pattern.projectile_damage = 20.0
	var aim := Vector2.ZERO
	_player.global_position = _boss.position + Vector2(-200, 0)
	pattern.fire(_ctx, _boss, aim, 0)
	assert_gt(_hp_lost(), 0.0, "in the arc")
	_player.hp = _player.stats.get_value(StatIds.MAX_HP)
	_player.global_position = _boss.position + Vector2(200, 0)
	pattern.fire(_ctx, _boss, aim, 0)
	assert_eq(_hp_lost(), 0.0, "behind the boss")
