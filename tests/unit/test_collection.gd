extends GutTest
## Portal shards and collection challenges (ADR 0023).


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func after_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func _skin(price: int) -> SkinData:
	var skin := SkinData.new()
	skin.id = &"test_skin"
	skin.name_key = "X"
	skin.character_id = &"ronin"
	skin.sprite_id = &"ronin_pc"
	skin.price = price
	return skin


func _win(character: StringName, seal: int) -> RunResult:
	var result := RunResult.new()
	result.character_id = character
	result.won = true
	result.difficulty = seal
	result.wave = 20
	return result


func test_collection_challenges_pay_shards_and_unlock_nothing() -> void:
	var challenges := SaveService.collection_challenges()
	assert_gt(challenges.size(), 20)
	for challenge in challenges:
		assert_true(challenge.is_collection(), "%s: shards and no unlock" % challenge.id)
		if challenge.kind in [ChallengeData.Kind.WIN_WITH, ChallengeData.Kind.WIN_SEAL_WITH]:
			assert_true(ContentDB.has_def(&"characters", challenge.character_id), "%s: unknown class" % challenge.id)


func test_a_win_pays_each_collection_challenge_once() -> void:
	var before := SaveService.profile.shards
	SaveService.record_run(_win(&"ronin", 0))
	var first := SaveService.profile.shards
	# Win with the swordswoman (100), Copper seal (40), wave 5 / 10 / 15 (30 + 40 + 60).
	assert_eq(first - before, 100 + 40 + 30 + 40 + 60)
	SaveService.record_run(_win(&"ronin", 0))
	assert_eq(SaveService.profile.shards, first, "already completed: nothing more")


func test_class_and_seal_challenge_needs_that_class() -> void:
	SaveService.record_run(_win(&"ronin", 2))
	assert_true(SaveService.profile.completed.has(&"collect_ronin_seal2"))
	assert_false(SaveService.profile.completed.has(&"collect_mage_seal2"))


func test_shards_survive_a_save_and_load() -> void:
	SaveService.profile.add_shards(250)
	var back := Profile.from_dict(SaveService.profile.to_dict())
	assert_eq(back.shards, 250)
	assert_eq(Profile.from_dict({"shards": -5}).shards, 0, "never negative")
	assert_eq(Profile.from_dict({"shards": "many"}).shards, 0, "wrong type ignored")


func test_buying_a_skin_spends_shards_once() -> void:
	var skin := _skin(150)
	SaveService.profile.add_shards(200)
	assert_true(SaveService.buy_skin(skin))
	assert_eq(SaveService.profile.shards, 50)
	assert_true(SaveService.profile.is_unlocked(&"skins", skin.id))
	assert_false(SaveService.buy_skin(skin), "already owned")
	assert_eq(SaveService.profile.shards, 50)


func test_a_skin_too_expensive_is_refused() -> void:
	SaveService.profile.add_shards(10)
	assert_false(SaveService.buy_skin(_skin(150)))
	assert_eq(SaveService.profile.shards, 10)
	assert_false(SaveService.profile.is_unlocked(&"skins", &"test_skin"))
	assert_false(SaveService.profile.spend_shards(-1), "no negative spending")


func test_skin_data_validation() -> void:
	assert_eq(_skin(100).validate().size(), 0)
	var bad := SkinData.new()
	assert_gt(bad.validate().size(), 0)


func test_past_statistics_pay_the_collection_at_load() -> void:
	SaveService.profile.wins_by_character[&"mage"] = 2
	SaveService.profile.best_difficulty_by_character[&"mage"] = 2
	SaveService.profile.runs_won = 2
	SaveService.profile.best_wave = 20
	SaveService.profile.total_kills = 1500
	SaveService.save_profile()
	SaveService.load_profile()
	var profile := SaveService.profile
	assert_true(profile.completed.has(&"collect_win_mage"))
	assert_true(profile.completed.has(&"collect_mage_seal2"))
	assert_true(profile.completed.has(&"collect_seal_2"))
	assert_true(profile.completed.has(&"collect_kills_1000"))
	assert_false(profile.completed.has(&"collect_win_ronin"), "another class: not won")
	assert_false(profile.completed.has(&"collect_mage_seal5"))
	var paid := profile.shards
	SaveService.load_profile()
	assert_eq(SaveService.profile.shards, paid, "paid once")


func test_a_prestige_skin_waits_for_the_astral_seal() -> void:
	var skin := _skin(700)
	skin.rarity = 3
	skin.required_seal = 5
	SaveService.profile.add_shards(1000)
	assert_false(SaveService.is_skin_available(skin))
	assert_false(SaveService.buy_skin(skin), "Astral seal not won yet")
	assert_eq(SaveService.profile.shards, 1000, "nothing spent")
	SaveService.profile.best_difficulty_by_character[&"mage"] = 5
	assert_true(SaveService.buy_skin(skin), "won by any hunter")
	assert_eq(SaveService.profile.shards, 300)


func test_skin_rarity_must_be_one_to_three() -> void:
	var skin := _skin(100)
	skin.rarity = 4
	assert_gt(skin.validate().size(), 0)
