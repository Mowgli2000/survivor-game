extends GutTest
## Validates every content definition under res://data/ (loaded through ContentDB).

var _keys: Dictionary


func before_all() -> void:
	ContentDB.reload()
	_keys = LocalizationKeys.load_table()


func _assert_common(def: Resource, category: StringName) -> void:
	var label := "%s/%s" % [category, def.resource_path.get_file()]
	assert_ne(String(def.get("id")), "", "%s: empty id" % label)
	assert_eq(String(def.get("id")), def.resource_path.get_file().get_basename(),
		"%s: id should match the file name" % label)
	var name_key: String = def.get("name_key")
	assert_true(_keys.has(name_key), "%s: missing localization key '%s'" % [label, name_key])


func test_expected_categories_exist() -> void:
	for category in [&"characters", &"weapons", &"enemies", &"upgrades", &"runs", &"stages", &"items", &"shop"]:
		assert_gt(ContentDB.get_all(category).size(), 0, "no content in data/%s" % category)


func test_enemies() -> void:
	for def in ContentDB.get_all(&"enemies"):
		var enemy := def as EnemyData
		assert_not_null(enemy, "data/enemies must contain EnemyData")
		_assert_common(enemy, &"enemies")
		assert_gt(enemy.max_hp, 0.0)
		assert_gt(enemy.radius, 0.0)
		assert_lte(enemy.radius, EnemyManager.MAX_ENEMY_RADIUS, "%s radius above MAX_ENEMY_RADIUS" % enemy.id)
		assert_gte(enemy.speed, 0.0)
		assert_gte(enemy.xp_value, 0)
		if enemy.movement == EnemyData.Movement.RANGED:
			assert_gt(enemy.preferred_distance, 0.0, "%s: ranged without distance" % enemy.id)
			assert_gt(enemy.fire_cooldown, 0.0)
			assert_gt(enemy.projectile_speed, 0.0)
		if enemy.sprite_id != &"":
			var sheet := enemy.get_sheet(false)
			assert_not_null(sheet, "%s: missing sprite sheet %s" % [enemy.id, enemy.sprite_id])
			if sheet != null:
				assert_true(sheet.has_animation(&"walk"), "%s: sheet needs walk" % enemy.id)


func test_weapons() -> void:
	for def in ContentDB.get_all(&"weapons"):
		var weapon := def as WeaponData
		assert_not_null(weapon, "data/weapons must contain WeaponData")
		_assert_common(weapon, &"weapons")
		assert_not_null(weapon.behavior, "%s has no behavior" % weapon.id)
		assert_gt(weapon.cooldown, 0.0)
		assert_gt(weapon.base_damage, 0.0)
		assert_gt(weapon.attack_range, 0.0)
		assert_gte(weapon.projectile_count, 1)
		assert_gt(weapon.projectile_lifetime, 0.0)
		assert_true(_keys.has(weapon.description_key), "%s: missing description key" % weapon.id)
		assert_eq(weapon.levels.size(), Tiers.COUNT - 1, "%s: one level entry per tier II..IV" % weapon.id)
		assert_gt(weapon.base_price, 0, "%s has no price" % weapon.id)
		for bonus in weapon.levels:
			assert_not_null(bonus, "%s: empty level entry" % weapon.id)
		if weapon.behavior is MeleeArcBehavior or weapon.behavior is BeamBehavior:
			assert_gt(weapon.area, 0.0, "%s: arc/beam weapons need an area" % weapon.id)
		if weapon.status != null:
			assert_gt(weapon.status_chance, 0.0)
			assert_gt(weapon.status.power, 0.0, "%s: status without power" % weapon.id)


func test_characters() -> void:
	for def in ContentDB.get_all(&"characters"):
		var character := def as CharacterData
		assert_not_null(character, "data/characters must contain CharacterData")
		_assert_common(character, &"characters")
		assert_not_null(character.starting_weapon, "%s has no starting weapon" % character.id)
		for stat in character.stat_overrides:
			assert_true(StatIds.is_valid(StringName(stat)), "%s: unknown stat '%s'" % [character.id, stat])


func test_upgrades() -> void:
	for def in ContentDB.get_all(&"upgrades"):
		var upgrade := def as UpgradeData
		assert_not_null(upgrade, "data/upgrades must contain UpgradeData")
		_assert_common(upgrade, &"upgrades")
		assert_gt(upgrade.weight, 0.0)
		assert_gt(upgrade.modifiers.size(), 0, "%s has no modifier" % upgrade.id)
		for mod in upgrade.modifiers:
			assert_true(StatIds.is_valid(mod.stat), "%s: unknown stat '%s'" % [upgrade.id, mod.stat])


func test_runs() -> void:
	assert_not_null(ContentDB.get_def(&"runs", Run.DEFAULT_CONFIG_ID), "data/runs/default.tres is required")
	for def in ContentDB.get_all(&"runs"):
		var run := def as RunConfig
		assert_not_null(run, "data/runs must contain RunConfig")
		assert_not_null(run.character)
		assert_not_null(run.stage, "%s has no stage" % run.id)
		assert_gt(run.upgrade_choices, 0)


func test_stages() -> void:
	for def in ContentDB.get_all(&"stages"):
		var stage := def as StageData
		assert_not_null(stage, "data/stages must contain StageData")
		assert_eq(String(stage.id), stage.resource_path.get_file().get_basename())
		assert_gte(stage.wave_count, 1)
		assert_gt(stage.duration_first, 0.0)
		assert_gt(stage.duration_last, 0.0)
		assert_gt(stage.spawn_pool.size(), 0, "%s: empty spawn pool" % stage.id)
		assert_gt(stage.max_enemies, 0)
		assert_gte(stage.heal_between_waves, 0.0)
		assert_gte(stage.elite_scale, 1.0)
		for entry in stage.spawn_pool:
			assert_not_null(entry.enemy, "%s: spawn entry without enemy" % stage.id)
			assert_between(entry.min_wave, 1, stage.wave_count, "%s: min_wave out of range" % stage.id)
			assert_lte(entry.enemy.radius * stage.elite_scale, EnemyManager.MAX_ENEMY_RADIUS,
				"%s: elite %s too big for the spatial grid" % [stage.id, entry.enemy.id])
		for event in stage.events:
			assert_not_null(event, "%s: empty event" % stage.id)
			assert_not_null(event.enemy, "%s: event without enemy" % stage.id)
			assert_between(event.wave, 1, stage.wave_count, "%s: event wave out of range" % stage.id)
			assert_gt(event.count, 0)
			assert_lt(event.at_time, stage.duration_at(event.wave),
				"%s: event of wave %d would never fire" % [stage.id, event.wave])
			if event.elite:
				assert_lte(event.enemy.radius * stage.elite_scale, EnemyManager.MAX_ENEMY_RADIUS)


func test_every_stat_has_a_localized_name() -> void:
	for stat: StringName in StatIds.DEFAULTS:
		assert_true(_keys.has(StatIds.localization_key(stat)), "missing key for stat '%s'" % stat)


func test_items() -> void:
	var items := ContentDB.get_all(&"items")
	assert_gte(items.size(), 15)
	for def in items:
		var item := def as ItemData
		assert_not_null(item, "data/items must contain ItemData")
		_assert_common(item, &"items")
		assert_between(item.tier, 1, Tiers.COUNT, "%s: tier out of range" % item.id)
		assert_gt(item.base_price, 0, "%s has no price" % item.id)
		assert_gte(item.max_count, 0)
		assert_gt(item.modifiers.size(), 0, "%s has no modifier" % item.id)
		for mod in item.modifiers:
			assert_true(StatIds.is_valid(mod.stat), "%s: unknown stat '%s'" % [item.id, mod.stat])


func test_shop_configs() -> void:
	for def in ContentDB.get_all(&"shop"):
		var shop := def as ShopConfig
		assert_not_null(shop, "data/shop must contain ShopConfig")
		assert_gt(shop.slot_count, 0)
		for array in [shop.weapon_tier_price, shop.tier_min_wave, shop.tier_base_chance,
				shop.tier_chance_per_wave, shop.tier_max_chance]:
			assert_eq(array.size(), Tiers.COUNT, "%s: one value per tier" % shop.resource_path)
	for def in ContentDB.get_all(&"runs"):
		assert_not_null((def as RunConfig).shop, "%s has no shop config" % def.resource_path)
