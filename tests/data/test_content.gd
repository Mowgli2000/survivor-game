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
		match enemy.movement:
			EnemyData.Movement.CHARGER:
				assert_gt(enemy.charge_range, 0.0, "%s: charge range" % enemy.id)
				assert_gt(enemy.charge_speed, 0.0)
				assert_gt(enemy.charge_duration, 0.0)
			EnemyData.Movement.KAMIKAZE:
				assert_gt(enemy.fuse_range, 0.0, "%s: fuse range" % enemy.id)
				assert_gt(enemy.blast_radius, 0.0)
			EnemyData.Movement.SPAWNER:
				assert_not_null(enemy.spawn_enemy, "%s: spawner without minion" % enemy.id)
				assert_gt(enemy.spawn_cooldown, 0.0)
				assert_gt(enemy.spawn_count, 0)
		if not enemy.phases.is_empty():
			assert_eq(enemy.phases[0].hp_ratio, 1.0, "%s: first phase must start at full HP" % enemy.id)
			for i in enemy.phases.size():
				var phase := enemy.phases[i]
				assert_false(phase.patterns.is_empty(), "%s phase %d: no pattern" % [enemy.id, i])
				if i > 0:
					assert_lt(phase.hp_ratio, enemy.phases[i - 1].hp_ratio, "%s: phases sorted by HP" % enemy.id)
				for pattern in phase.patterns:
					assert_eq(pattern.validate(), "", "%s phase %d: %s" % [enemy.id, i, pattern.validate()])
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
		assert_not_null(weapon.icon, "%s has no icon" % weapon.id)
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
		if character.sprite_id != &"":
			var sheet := load("res://assets/sprites/%s.tres" % character.sprite_id) as SpriteSheet
			assert_not_null(sheet, "%s: missing sprite sheet %s" % [character.id, character.sprite_id])
			if sheet != null:
				assert_true(sheet.has_animation(&"idle") and sheet.has_animation(&"walk"),
					"%s: player sheet needs idle and walk" % character.id)


## Every challenge unlocks existing, locked content; every locked content has a challenge.
func test_challenges() -> void:
	var targets := {}
	for def in ContentDB.get_all(&"challenges"):
		var challenge := def as ChallengeData
		assert_not_null(challenge, "data/challenges must contain ChallengeData")
		_assert_common(challenge, &"challenges")
		var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
		assert_not_null(target, "%s: unknown unlock %s/%s" % [challenge.id, challenge.unlock_category, challenge.unlock_id])
		if target != null:
			assert_true(target.get(&"locked"), "%s unlocks %s, which is not locked" % [challenge.id, challenge.unlock_id])
		if challenge.kind == ChallengeData.Kind.WIN_WITH:
			assert_true(ContentDB.has_def(&"characters", challenge.character_id), "%s: unknown character" % challenge.id)
		if challenge.kind == ChallengeData.Kind.KILL_ENEMY:
			assert_true(ContentDB.has_def(&"enemies", challenge.enemy_id), "%s: unknown enemy" % challenge.id)
		targets["%s/%s" % [challenge.unlock_category, challenge.unlock_id]] = true
	for category in [&"characters", &"weapons", &"items"]:
		for def in ContentDB.get_all(category):
			if def.get(&"locked"):
				assert_true(targets.has("%s/%s" % [category, def.get(&"id")]), "%s is locked forever" % def.get(&"id"))
	var unlocked_characters := 0
	for def in ContentDB.get_all(&"characters"):
		if not (def as CharacterData).locked:
			unlocked_characters += 1
	assert_gt(unlocked_characters, 0, "at least one playable character from the start")


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
	assert_gte(items.size(), 28)
	for def in items:
		var item := def as ItemData
		assert_not_null(item, "data/items must contain ItemData")
		_assert_common(item, &"items")
		assert_between(item.tier, 1, Tiers.COUNT, "%s: tier out of range" % item.id)
		assert_gt(item.base_price, 0, "%s has no price" % item.id)
		assert_not_null(item.icon, "%s has no icon" % item.id)
		assert_gte(item.max_count, 0)
		assert_true(item.modifiers.size() > 0 or item.effects.size() > 0, "%s does nothing" % item.id)
		for effect in item.effects:
			assert_not_null(effect, "%s: empty effect" % item.id)
			if effect != null:
				assert_eq(effect.validate(), PackedStringArray(), "%s effect" % item.id)
		if not item.effects.is_empty():
			assert_true(_keys.has(item.effect_key), "%s: effect text key" % item.id)
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
