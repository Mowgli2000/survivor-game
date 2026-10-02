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


func _weapon(id: StringName, level_count: int) -> WeaponData:
	var weapon := WeaponData.new()
	weapon.id = id
	for i in level_count:
		weapon.levels.append(WeaponLevel.new())
	return weapon


func test_stat_offers_are_distinct_and_limited() -> void:
	var p := Progression.new(5.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pool: Array[UpgradeData] = [
		_upgrade(&"a", StatIds.ARMOR, 1.0), _upgrade(&"b", StatIds.ARMOR, 1.0),
		_upgrade(&"c", StatIds.ARMOR, 1.0), _upgrade(&"d", StatIds.ARMOR, 1.0)]
	var no_weapons: Array[WeaponData] = []
	var offers := p.roll_offers(pool, no_weapons, {}, 6, 3, rng)
	assert_eq(offers.size(), 3)
	assert_ne(offers[0].upgrade, offers[1].upgrade)
	assert_ne(offers[1].upgrade, offers[2].upgrade)
	var small_pool: Array[UpgradeData] = [pool[0], pool[1]]
	assert_eq(p.roll_offers(small_pool, no_weapons, {}, 6, 3, rng).size(), 2)


func test_weapon_offers_respect_ownership_slots_and_max_level() -> void:
	var p := Progression.new(5.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var no_stats: Array[UpgradeData] = []
	var owned_weapon := _weapon(&"owned", 4)
	var maxed_weapon := _weapon(&"maxed", 4)
	var new_weapon := _weapon(&"new", 4)
	var pool: Array[WeaponData] = [owned_weapon, maxed_weapon, new_weapon]
	var owned := {owned_weapon: 2, maxed_weapon: 5}

	var offers := p.roll_offers(no_stats, pool, owned, 1, 5, rng)
	assert_eq(offers.size(), 2, "maxed weapon is never offered")
	for offer in offers:
		if offer.weapon == owned_weapon:
			assert_eq(offer.kind, UpgradeOffer.Kind.WEAPON_LEVEL)
			assert_eq(offer.level, 3)
		else:
			assert_eq(offer.weapon, new_weapon)
			assert_eq(offer.kind, UpgradeOffer.Kind.NEW_WEAPON)

	var no_slot := p.roll_offers(no_stats, pool, owned, 0, 5, rng)
	assert_eq(no_slot.size(), 1, "no new weapon when all slots are taken")
	assert_eq(no_slot[0].weapon, owned_weapon)


func test_apply_upgrade_changes_stats_and_consumes_pending() -> void:
	var p := Progression.new(5.0, 1.0)
	p.add_xp(5)
	var stats := StatBlock.from_defaults()
	p.apply_upgrade(_upgrade(&"plating", StatIds.ARMOR, 4.0), stats)
	assert_eq(stats.get_value(StatIds.ARMOR), 4.0)
	assert_eq(p.pending_level_ups, 0)
