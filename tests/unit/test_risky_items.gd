extends GutTest
## The risky items (Lead armor, Blood pact, Unstable idol, Executioner's mask): stats and unlock challenges.

const RISKY: Array[StringName] = [&"lead_armor", &"blood_pact", &"unstable_idol", &"executioner_mask"]


func before_all() -> void:
	ContentDB.reload()


func _stat_block_with(item_id: StringName) -> StatBlock:
	var stats := StatBlock.new()
	for stat: StringName in StatIds.DEFAULTS:
		stats.set_base(stat, StatIds.DEFAULTS[stat])
	for modifier in (ContentDB.get_def(&"items", item_id) as ItemData).modifiers:
		stats.add_modifier(modifier)
	return stats


func test_risky_items_are_unique_and_locked() -> void:
	for id in RISKY:
		var item := ContentDB.get_def(&"items", id) as ItemData
		assert_not_null(item, "%s exists" % id)
		assert_eq(item.max_count, 1, "%s is unique" % id)
		assert_true(item.locked, "%s is locked" % id)


func test_blood_pact_doubles_damage_and_halves_hp() -> void:
	var stats := _stat_block_with(&"blood_pact")
	assert_almost_eq(stats.get_value(StatIds.DAMAGE), 2.0, 0.0001)
	assert_almost_eq(stats.get_value(StatIds.MAX_HP), 50.0, 0.0001)


func test_lead_armor_trades_speed_for_armor_and_hp() -> void:
	var stats := _stat_block_with(&"lead_armor")
	assert_almost_eq(stats.get_value(StatIds.ARMOR), 8.0, 0.0001)
	assert_almost_eq(stats.get_value(StatIds.MAX_HP), 130.0, 0.0001)
	assert_almost_eq(stats.get_value(StatIds.ATTACK_SPEED), 0.85, 0.0001)
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 255.0, 0.0001)


func test_unstable_idol_stats() -> void:
	var stats := _stat_block_with(&"unstable_idol")
	assert_almost_eq(stats.get_value(StatIds.ATTACK_SPEED), 1.3, 0.0001)
	assert_almost_eq(stats.get_value(StatIds.DAMAGE), 1.2, 0.0001)
	assert_almost_eq(stats.get_value(StatIds.MAX_HP), 65.0, 0.0001)
	assert_almost_eq(stats.get_value(StatIds.MOVE_SPEED), 255.0, 0.0001)


func test_executioner_mask_effect_values_are_valid() -> void:
	var item := ContentDB.get_def(&"items", &"executioner_mask") as ItemData
	assert_eq(item.effects.size(), 1)
	var effect := item.effects[0] as TargetDamageEffect
	assert_not_null(effect)
	assert_almost_eq(effect.vs_priority, 1.5, 0.0001)
	assert_almost_eq(effect.vs_common, 0.8, 0.0001)
	assert_eq(effect.validate().size(), 0)


func test_each_risky_item_has_a_seal_challenge_with_its_hero() -> void:
	var expected := {&"lead_armor": [&"ronin", 3], &"executioner_mask": [&"hero", 4],
		&"unstable_idol": [&"gunslinger", 4], &"blood_pact": [&"berserker", 5]}
	for id: StringName in expected:
		var found: ChallengeData = null
		for def in ContentDB.get_all(&"challenges"):
			var challenge := def as ChallengeData
			if challenge.unlock_id == id:
				found = challenge
		assert_not_null(found, "%s has a challenge" % id)
		if found == null:
			continue
		assert_eq(found.kind, ChallengeData.Kind.WIN_SEAL_WITH)
		assert_eq(found.character_id, expected[id][0], "%s hero" % id)
		assert_eq(found.threshold, expected[id][1], "%s seal" % id)
		assert_true(ContentDB.has_def(&"characters", found.character_id))
