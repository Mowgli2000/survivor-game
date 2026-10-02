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
	for category in [&"characters", &"weapons", &"enemies", &"upgrades", &"runs"]:
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
		assert_gt(run.spawn_pool.size(), 0)
		for entry in run.spawn_pool:
			assert_not_null(entry.enemy, "%s: spawn entry without enemy" % run.id)
		assert_gt(run.upgrade_choices, 0)


func test_every_stat_has_a_localized_name() -> void:
	for stat: StringName in StatIds.DEFAULTS:
		assert_true(_keys.has(StatIds.localization_key(stat)), "missing key for stat '%s'" % stat)
