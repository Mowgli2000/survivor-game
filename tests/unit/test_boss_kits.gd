extends GutTest
## The kits of the final bosses of the seals 2-6: each boss has attacks of its own (no pattern shared with
## another boss), and each mechanic hurts who it should and spares who it should.

const BOSSES: Array[StringName] = [&"shogun", &"iron_boss_final", &"silver_boss_final", &"gold_boss_final",
	&"obsidian_boss_final", &"astral_boss_final"]

var _player: Player
var _enemies: EnemyManager
var _ctx: BossContext
var _boss: Enemy


func before_each() -> void:
	var arena := Rect2(-2000, -2000, 4000, 4000)
	_player = Player.new()
	_player.setup(CharacterData.new(), arena)
	_player.invincible = false
	_player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(_player)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
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
	_boss = _enemies.spawn(ContentDB.get_def(&"enemies", &"iron_boss_final"), Vector2(500, 0))


func _lost() -> float:
	return _player.stats.get_value(StatIds.MAX_HP) - _player.hp


func _heal() -> void:
	_player.hp = _player.stats.get_value(StatIds.MAX_HP)
	_player._invulnerable = 0.0  # the blink after a hit would hide the next one


func _scripts_of(boss: StringName) -> Dictionary:
	var result := {}
	for phase in ContentDB.get_def(&"enemies", boss).phases:
		for pattern in phase.patterns:
			assert_eq(pattern.validate(), "", "%s: a pattern is valid" % boss)
			result[pattern.get_script().get_global_name()] = true
	return result


func test_no_two_final_bosses_share_an_attack() -> void:
	for i in BOSSES.size():
		var mine := _scripts_of(BOSSES[i])
		for j in range(i + 1, BOSSES.size()):
			var theirs := _scripts_of(BOSSES[j])
			for name in mine:
				if name == &"SummonPattern" or name == &"ComboPattern":
					continue  # calling minions is a plain building block, not a signature attack
				assert_false(theirs.has(name), "%s and %s both use %s" % [BOSSES[i], BOSSES[j], name])


func test_every_final_boss_has_four_or_more_different_attacks() -> void:
	for boss in BOSSES:
		assert_gte(_scripts_of(boss).size(), 4, "%s has its own kit" % boss)  # no summons: the final boss is a duel


func test_crack_rays_hurt_on_a_spoke_and_spare_between_two() -> void:
	var pattern := CrackRaysPattern.new()
	var aim := Vector2(200, 0)
	var spoke := pattern.ray_angle(_boss, aim, 0, 0)
	_player.global_position = _boss.position + Vector2.from_angle(spoke) * 300.0
	pattern.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "on a spoke")
	_heal()
	_player.global_position = _boss.position + Vector2.from_angle(spoke + PI / pattern.rays) * 300.0
	pattern.fire(_ctx, _boss, aim, 0)
	assert_eq(_lost(), 0.0, "between spokes")


func test_every_final_boss_has_a_finale_combo_in_its_last_phase() -> void:
	for boss in BOSSES:
		var data := load("res://data/enemies/%s.tres" % boss) as EnemyData
		var last: BossPhase = data.phases[data.phases.size() - 1]
		var combos := 0
		for pattern in last.patterns:
			if pattern is ComboPattern:
				combos += 1
				assert_eq(pattern.validate(), "", "%s: the combo is valid" % boss)
		assert_eq(combos, 1, "%s has one finale attack in its last phase" % boss)
		for phase in data.phases.slice(0, data.phases.size() - 1):
			for pattern in phase.patterns:
				assert_false(pattern is ComboPattern, "%s: the finale comes only in the last phase" % boss)


func test_a_combo_fires_all_its_parts_on_the_same_volley() -> void:
	var data := load("res://data/enemies/iron_boss_final.tres") as EnemyData
	var combo: ComboPattern
	for pattern in data.phases[data.phases.size() - 1].patterns:
		if pattern is ComboPattern:
			combo = pattern
	var aim := Vector2(300, 0)
	_player.global_position = aim  # where the pillar part falls
	combo.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "a part of the combo hurts")
	_heal()
	_player.global_position = _boss.position + Vector2(-2000, 0)
	combo.fire(_ctx, _boss, aim, 0)
	assert_eq(_lost(), 0.0, "far from every part: safe")


func test_shock_rings_hurt_on_the_ring_and_not_between_two_rings() -> void:
	var pattern := ShockRingsPattern.new()
	_player.global_position = _boss.position + Vector2(pattern.first_radius, 0)
	pattern.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_gt(_lost(), 0.0, "on the ring")
	_heal()
	_player.global_position = _boss.position + Vector2((pattern.ring_radius(0) + pattern.ring_radius(1)) * 0.5, 0)
	pattern.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_eq(_lost(), 0.0, "in the free ground between two rings")
	for repeat in 2:  # the free ground between two neighbouring rings stays wider than a hero
		var gap := pattern.ring_radius(repeat + 1) - pattern.band(pattern.ring_radius(repeat + 1)) - pattern.ring_radius(repeat) - pattern.band(pattern.ring_radius(repeat))
		assert_gt(gap, _player.radius * 2.0, "rings %d and %d leave room to stand" % [repeat, repeat + 1])


func test_pillar_drop_follows_the_player_and_rune_seal_is_wide() -> void:
	var pillar := PillarDropPattern.new()
	pillar.repeats = 3
	_player.global_position = Vector2(-100, 0)
	pillar.telegraph(_ctx, _boss, _player.global_position)
	pillar.fire(_ctx, _boss, _player.global_position, 0)
	assert_gt(_lost(), 0.0, "the first block lands on the spot shown")
	_heal()
	_player.global_position = Vector2(-700, 300)
	pillar.fire(_ctx, _boss, _player.global_position, 1)
	assert_eq(_lost(), 0.0, "the player moved away from the second block's spot")
	var seal := RuneSealPattern.new()
	_player.global_position = Vector2(seal.seal_radius * 0.9, 0)
	seal.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_gt(_lost(), 0.0, "near the edge of the seal")
	_heal()
	_player.global_position = Vector2(seal.seal_radius + 80.0, 0)
	seal.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_eq(_lost(), 0.0, "outside the seal")


func test_ice_spike_line_needs_one_volley_per_spike_and_hurts_on_its_line() -> void:
	var pattern := IceSpikeLinePattern.new()
	pattern.repeats = 3
	assert_ne(pattern.validate(), "", "volleys must equal spikes")
	pattern.repeats = pattern.spikes
	assert_eq(pattern.validate(), "")
	var aim := Vector2.ZERO
	_player.global_position = pattern.spot(_boss, aim, 2)
	pattern.fire(_ctx, _boss, aim, 2)
	assert_gt(_lost(), 0.0, "on the third spike")
	_heal()
	pattern.fire(_ctx, _boss, aim, 5)
	assert_eq(_lost(), 0.0, "the sixth spike is elsewhere")


func test_frost_wall_hurts_the_solid_part_and_leaves_the_gap_clear() -> void:
	var pattern := FrostWallPattern.new()
	var aim := Vector2.ZERO
	var pieces := pattern.pieces(_boss, aim, 0)
	_player.global_position = (pieces[0][0] + pieces[0][1]) * 0.5
	pattern.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "in the wall")
	_heal()
	_player.global_position = (pieces[0][1] + pieces[1][0]) * 0.5
	pattern.fire(_ctx, _boss, aim, 0)
	assert_eq(_lost(), 0.0, "in the gap")


func test_freezing_patch_keeps_hurting_on_every_repeat() -> void:
	var pattern := FreezingPatchPattern.new()
	pattern.repeats = 4
	_player.global_position = Vector2(50, 0)
	pattern.fire(_ctx, _boss, Vector2.ZERO, 0)
	var first := _lost()
	assert_gt(first, 0.0)
	_player._invulnerable = 0.0
	pattern.fire(_ctx, _boss, Vector2.ZERO, 3)
	assert_gt(_lost(), first, "still hurting on the fourth repeat")


func test_club_shockwave_and_wing_blast_have_their_safe_places() -> void:
	var club := ClubShockwavePattern.new()
	var aim := Vector2.ZERO
	_player.global_position = _boss.position + Vector2(-300, 0)
	club.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "on the band")
	_heal()
	_player.global_position = _boss.position + Vector2(-300, 400)
	club.fire(_ctx, _boss, aim, 0)
	assert_eq(_lost(), 0.0, "beside the band")
	var wings := WingBlastPattern.new()
	_player.global_position = _boss.position + Vector2(-200, 0)  # in front, toward the aim
	wings.fire(_ctx, _boss, aim, 0)
	assert_eq(_lost(), 0.0, "in front of the demon is safe")
	_player.global_position = _boss.position + Vector2(0, 200)  # at its side
	wings.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "at its side")


func test_chain_lash_and_beam_require_matching_volleys_and_hurt_on_their_line() -> void:
	var lash := ChainLashPattern.new()
	lash.repeats = 2
	assert_ne(lash.validate(), "")
	lash.repeats = lash.lashes
	var aim := Vector2.ZERO
	_player.global_position = _boss.position + Vector2.from_angle(lash.lash_angle(_boss, aim, 0)) * 300.0
	lash.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "under the first lash")
	_heal()
	var beam := FireBeamPattern.new()
	beam.repeats = 10
	_player.global_position = _boss.position + Vector2.from_angle(beam.beam_angle(_boss, aim, 4)) * 300.0
	beam.fire(_ctx, _boss, aim, 4)
	assert_gt(_lost(), 0.0, "in the beam")
	_heal()
	beam.fire(_ctx, _boss, aim, 8)
	assert_eq(_lost(), 0.0, "the beam is elsewhere by then")


func test_flame_checker_waves_alternate_their_spots() -> void:
	var pattern := FlameCheckerPattern.new()
	var aim := Vector2.ZERO
	_player.global_position = pattern.spot(aim, 0, 0)
	pattern.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "on a first-wave column")
	_heal()
	pattern.fire(_ctx, _boss, aim, 1)
	assert_eq(_lost(), 0.0, "the second wave is between the first one's columns")


func test_hive_queen_mechanics_hurt_and_spawn() -> void:
	var larva: EnemyData = ContentDB.get_def(&"enemies", &"obsidian_runner")
	var eggs := EggClutchPattern.new()
	eggs.larva = larva
	var aim := Vector2.ZERO
	_player.global_position = eggs.egg(_boss, aim, 0)
	var before := _enemies.active_count()
	eggs.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "next to an egg")
	assert_eq(_enemies.active_count(), before + eggs.eggs, "a larva comes out of every egg")
	_heal()
	var net := WebNetPattern.new()
	var cell := Vector2(net.spacing * 0.5, net.spacing * 0.5)  # between two threads of each direction
	_player.global_position = cell
	net.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_eq(_lost(), 0.0, "in a square of the net")
	_player.global_position = Vector2(net.spacing, 0)  # on a vertical thread
	net.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_gt(_lost(), 0.0, "on a thread")
	_heal()
	var cage := LegCagePattern.new()
	_player.global_position = Vector2.ZERO
	cage.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_eq(_lost(), 0.0, "the middle of the ring is spared by the first stab")
	cage.fire(_ctx, _boss, Vector2.ZERO, 1)
	assert_gt(_lost(), 0.0, "and hit by the second")
	var pools := VenomPoolsPattern.new()
	pools.repeats = 4
	_heal()
	_player.global_position = pools.pool(_boss, Vector2(100, 0), 1)
	pools.fire(_ctx, _boss, Vector2(100, 0), 2)
	assert_gt(_lost(), 0.0, "in a pool, whatever the repeat")


func test_venom_spit_shoots_blobs() -> void:
	var spit := VenomSpitPattern.new()
	spit.fire(_ctx, _boss, Vector2.ZERO, 0)
	assert_eq(_ctx.enemy_projectiles.active_count(), spit.blobs)


func test_dragon_mechanics() -> void:
	var aim := Vector2.ZERO
	var breath := FireBreathPattern.new()
	breath.repeats = 7
	_player.global_position = _boss.position + Vector2.from_angle(breath.jet_angle(_boss, aim, 3)) * 350.0
	breath.fire(_ctx, _boss, aim, 3)
	assert_gt(_lost(), 0.0, "in the jet")
	_heal()
	breath.fire(_ctx, _boss, aim, 6)
	assert_eq(_lost(), 0.0, "the jet has moved on")
	var tail := TailSweepPattern.new()
	_player.global_position = _boss.position + Vector2(-(tail.inner + tail.outer) * 0.5, 0)
	tail.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "under the tail")
	_heal()
	_player.global_position = _boss.position + Vector2(-(tail.inner * 0.4), 0)
	tail.fire(_ctx, _boss, aim, 0)
	assert_eq(_lost(), 0.0, "right against the dragon")
	var meteors := MeteorShowerPattern.new()
	_player.global_position = meteors.crater(_boss, aim, 0)
	meteors.fire(_ctx, _boss, aim, 0)
	assert_gt(_lost(), 0.0, "in a crater")
	_heal()
	_player.global_position = aim + _dir_across(aim) * meteors.gap * 0.5  # the gap between two craters
	meteors.fire(_ctx, _boss, aim, 0)
	assert_eq(_lost(), 0.0, "between two craters")
	var flyby := DragonFlybyPattern.new()
	flyby.fire(_ctx, _boss, Vector2(-500, 0), 0)
	assert_lt(_boss.forced_velocity.x, 0.0, "the dragon flies toward the aim")
	var storm := StormFrontPattern.new()
	storm.repeats = 5
	_heal()
	_player.global_position = storm.spot(_boss, aim, 2)
	storm.fire(_ctx, _boss, aim, 2)
	assert_gt(_lost(), 0.0, "under the third bolt")


func _dir_across(aim: Vector2) -> Vector2:
	var offset := aim - _boss.position
	return offset.normalized().orthogonal()
