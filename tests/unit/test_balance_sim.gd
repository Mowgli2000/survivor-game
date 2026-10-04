extends GutTest
## Balance simulator (ADR 0019): run hooks, build policy scoring, power indicators.


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.TEST_PATH))
	SaveService.load_profile()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.TEST_PATH))
	SaveService.load_profile()


func _modifier(stat: StringName, flat: float, percent: float = 0.0) -> StatModifier:
	var m := StatModifier.new()
	m.stat = stat
	m.flat = flat
	m.percent = percent
	return m


func test_simulated_runs_never_touch_the_profile() -> void:
	var setup := RunSetup.new()
	setup.character = ContentDB.get_def(&"characters", &"ronin")
	setup.weapon = ContentDB.get_def(&"weapons", &"katana")
	setup.difficulty = ContentDB.get_def(&"difficulties", &"danger_0")
	var run: Run = preload("res://src/run/run.tscn").instantiate()
	run.setup = setup
	run.record_profile = false
	add_child_autofree(run)
	run._record_run(true)
	get_tree().paused = false
	assert_eq(SaveService.profile.max_difficulty(&"ronin"), 0, "no seal unlocked by a simulation")


func test_unlock_all_offers_locked_content() -> void:
	var run: Run = preload("res://src/run/run.tscn").instantiate()
	run.unlock_all = true
	var locked := ContentDB.get_all(&"items").filter(func(i: ItemData) -> bool: return i.locked)
	assert_eq(run._unlocked(&"items").size(), ContentDB.get_all(&"items").size())
	assert_gt(locked.size(), 0, "some items are locked in a fresh profile")
	run.free()


func test_policies_value_offense_and_defense_differently() -> void:
	var dps := BalancePolicy.new("dps")
	var tank := BalancePolicy.new("tank")
	var damage: Array[StatModifier] = [_modifier(StatIds.DAMAGE, 0.0, 0.1)]
	var armor: Array[StatModifier] = [_modifier(StatIds.ARMOR, 1.0)]
	assert_gt(dps.score_modifiers(damage, 5), dps.score_modifiers(armor, 5))
	assert_gt(tank.score_modifiers(armor, 5), tank.score_modifiers(damage, 5))
	var malus: Array[StatModifier] = [_modifier(StatIds.DAMAGE, 0.0, -0.1)]
	assert_lt(dps.score_modifiers(malus, 5), 0.0, "a malus costs points")


func test_getting_hurt_raises_the_value_of_defense() -> void:
	var policy := BalancePolicy.new("dps")
	var armor: Array[StatModifier] = [_modifier(StatIds.ARMOR, 3.0)]
	var calm := policy.score_modifiers(armor, 5)
	policy.last_wave_damage_ratio = 0.8
	assert_gt(policy.score_modifiers(armor, 5), calm)


func test_economy_policy_wants_harvest_early_only() -> void:
	var policy := BalancePolicy.new("economy")
	var harvest: Array[StatModifier] = [_modifier(StatIds.HARVEST, 5.0)]
	assert_gt(policy.score_modifiers(harvest, 3), policy.score_modifiers(harvest, 15))


func test_sheet_dps_grows_with_tier_and_damage_stat() -> void:
	var holder := WeaponHolder.new()
	autofree(holder)
	var stats := StatBlock.from_defaults()
	holder.add_weapon(ContentDB.get_def(&"weapons", &"pulse"), 1)
	var low := BalanceSimTools.sheet_dps(holder, stats)
	holder.upgrade_slot(0)
	var tier_2 := BalanceSimTools.sheet_dps(holder, stats)
	assert_gt(low, 0.0)
	assert_gt(tier_2, low)


func test_model_counts_more_targets_for_area_weapons() -> void:
	var model := BalanceSimTools
	var axe: WeaponData = ContentDB.get_def(&"weapons", &"heavy_axe")
	var sling: WeaponData = ContentDB.get_def(&"weapons", &"sling")
	assert_gt(model.targets_hit(axe, WeaponStats.compute(axe, 1)), model.targets_hit(sling, WeaponStats.compute(sling, 1)))
	assert_eq(model.targets_hit(sling, WeaponStats.compute(sling, 1)), 1.0)
