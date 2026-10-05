extends GutTest
## Seal rewards: winning a seal (any character) unlocks a weapon and two items.


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func after_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func _seal_challenges(level: int) -> Array[ChallengeData]:
	var list: Array[ChallengeData] = []
	for challenge in SaveService.all_challenges():
		if challenge.kind == ChallengeData.Kind.WIN_SEAL and challenge.threshold == level:
			list.append(challenge)
	return list


func _win(level: int) -> Array[ChallengeData]:
	var result := RunResult.new()
	result.character_id = &"drifter"
	result.won = true
	result.difficulty = level
	result.wave = 20
	return SaveService.record_run(result)


func test_every_seal_rewards_a_weapon_and_two_locked_items() -> void:
	for level in 6:
		var challenges := _seal_challenges(level)
		assert_eq(challenges.size(), 3, "seal %d" % level)
		var weapons := 0
		for challenge in challenges:
			var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
			assert_not_null(target, String(challenge.unlock_id))
			assert_true(target.get(&"locked"), "%s starts locked" % challenge.unlock_id)
			weapons += int(challenge.unlock_category == &"weapons")
		assert_eq(weapons, 1, "seal %d gives one weapon" % level)


func test_winning_a_seal_unlocks_its_rewards_and_the_lower_ones() -> void:
	var unlocked := _win(2)
	for level in 3:
		for challenge in _seal_challenges(level):
			var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
			assert_true(SaveService.is_unlocked(challenge.unlock_category, target), String(challenge.id))
			assert_true(unlocked.has(challenge), "shown on the end screen: %s" % challenge.id)
	for challenge in _seal_challenges(3):
		var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
		assert_false(SaveService.is_unlocked(challenge.unlock_category, target), "seal 3 not won yet")


func test_a_lost_run_unlocks_nothing() -> void:
	var result := RunResult.new()
	result.character_id = &"drifter"
	result.won = false
	result.difficulty = 5
	SaveService.record_run(result)
	for challenge in _seal_challenges(0):
		var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
		assert_false(SaveService.is_unlocked(challenge.unlock_category, target))


func test_seal_info_announces_the_reward_until_it_is_won() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	assert_ne(screen.seal_reward_text(0), "", "Copper reward announced")
	_win(0)
	assert_eq(screen.seal_reward_text(0), "", "nothing left to win at Copper")
	assert_ne(screen.seal_reward_text(1), "")


func test_seals_won_before_the_rewards_existed_grant_them_at_load() -> void:
	SaveService.profile.best_difficulty_by_character[&"ronin"] = 1  # won Iron long ago
	SaveService.save_profile()
	SaveService.load_profile()
	for level in 2:
		for challenge in _seal_challenges(level):
			var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
			assert_true(SaveService.is_unlocked(challenge.unlock_category, target), String(challenge.id))
	for challenge in _seal_challenges(2):
		var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
		assert_false(SaveService.is_unlocked(challenge.unlock_category, target))
