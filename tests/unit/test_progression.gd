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


func test_stat_offers_are_distinct_and_limited() -> void:
	var p := Progression.new(5.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pool: Array[UpgradeData] = [
		_upgrade(&"a", StatIds.ARMOR, 1.0), _upgrade(&"b", StatIds.ARMOR, 1.0),
		_upgrade(&"c", StatIds.ARMOR, 1.0), _upgrade(&"d", StatIds.ARMOR, 1.0)]
	var offers := p.roll_offers(pool, 3, rng)
	assert_eq(offers.size(), 3)
	assert_ne(offers[0].upgrade, offers[1].upgrade)
	assert_ne(offers[1].upgrade, offers[2].upgrade)
	var small_pool: Array[UpgradeData] = [pool[0], pool[1]]
	assert_eq(p.roll_offers(small_pool, 3, rng).size(), 2)


func test_apply_offer_scales_with_tier_and_consumes_pending() -> void:
	var p := Progression.new(5.0, 1.0)
	p.add_xp(5)
	var stats := StatBlock.from_defaults()
	p.apply_offer(UpgradeOffer.for_stat(_upgrade(&"plating", StatIds.ARMOR, 5.0), 2), stats)
	assert_almost_eq(stats.get_value(StatIds.ARMOR), 8.0, 0.001, "tier II = x1.6")
	assert_eq(p.pending_level_ups, 0)


func test_integer_stats_are_rounded_when_scaled() -> void:
	var offer := UpgradeOffer.for_stat(_upgrade(&"multi", StatIds.PROJECTILE_COUNT, 1.0), 3)
	assert_eq(offer.scaled_modifiers()[0].flat, 2.0, "1 x 2.4 rounds to 2")


func test_scaling_never_changes_the_resource() -> void:
	var upgrade := _upgrade(&"plating", StatIds.ARMOR, 5.0)
	UpgradeOffer.for_stat(upgrade, 4).scaled_modifiers()
	assert_eq(upgrade.modifiers[0].flat, 5.0)


func test_offers_get_a_tier_from_the_shop_config() -> void:
	var p := Progression.new(5.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var pool: Array[UpgradeData] = [_upgrade(&"a", StatIds.ARMOR, 1.0), _upgrade(&"b", StatIds.ARMOR, 1.0)]
	for offer in p.roll_offers(pool, 2, rng):
		assert_eq(offer.tier, 1, "no config: tier I")
	var config := ShopConfig.new()
	config.tier_min_wave = [1, 1, 1, 1]
	config.tier_base_chance = [0.0, 0.0, 0.0, 1.0]
	config.tier_max_chance = [0.0, 1.0, 1.0, 1.0]
	for offer in p.roll_offers(pool, 2, rng, config, 5):
		assert_eq(offer.tier, 4)
