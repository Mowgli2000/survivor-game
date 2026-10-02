extends GutTest


func _upgrade(id: StringName, stat: StringName, flat: float) -> UpgradeData:
	var mod := StatModifier.new()
	mod.stat = stat
	mod.flat = flat
	var upgrade := UpgradeData.new()
	upgrade.id = id
	upgrade.modifiers = [mod]
	return upgrade


func test_xp_curve_grows() -> void:
	var p := Progression.new(5.0, 1.35)
	assert_eq(p.xp_needed(1), 5)
	assert_gt(p.xp_needed(10), p.xp_needed(5))


func test_add_xp_levels_up_and_queues() -> void:
	var p := Progression.new(5.0, 1.0)  # 5, 10, 15...
	watch_signals(p)
	p.add_xp(4)
	assert_eq(p.level, 1)
	p.add_xp(12)  # 16 total: level 2 (5), level 3 (10), 1 left
	assert_eq(p.level, 3)
	assert_eq(p.pending_level_ups, 2)
	assert_eq(p.xp, 1)
	assert_signal_emit_count(p, "leveled_up", 2)


func test_roll_choices_are_distinct_and_limited() -> void:
	var p := Progression.new(5.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pool: Array[UpgradeData] = [
		_upgrade(&"a", StatIds.ARMOR, 1.0), _upgrade(&"b", StatIds.ARMOR, 1.0),
		_upgrade(&"c", StatIds.ARMOR, 1.0), _upgrade(&"d", StatIds.ARMOR, 1.0)]
	var choices := p.roll_choices(pool, 3, rng)
	assert_eq(choices.size(), 3)
	assert_ne(choices[0], choices[1])
	assert_ne(choices[1], choices[2])
	assert_eq(p.roll_choices(pool.slice(0, 2), 3, rng).size(), 2)


func test_apply_upgrade_changes_stats_and_consumes_pending() -> void:
	var p := Progression.new(5.0, 1.0)
	p.add_xp(5)
	var stats := StatBlock.from_defaults()
	p.apply_upgrade(_upgrade(&"plating", StatIds.ARMOR, 4.0), stats)
	assert_eq(stats.get_value(StatIds.ARMOR), 4.0)
	assert_eq(p.pending_level_ups, 0)
