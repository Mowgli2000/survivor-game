extends GutTest
## Meta progression (ADR 0015): profile, challenges, SaveService.


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.TEST_PATH))
	SaveService.path = SaveService.TEST_PATH
	SaveService.load_profile()


func after_all() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.TEST_PATH))
	SaveService.load_profile()


func _result(won: bool, wave: int, kills: int, character: StringName = &"drifter") -> RunResult:
	var result := RunResult.new()
	result.character_id = character
	result.won = won
	result.wave = wave
	result.kills = kills
	return result


func _challenge(kind: ChallengeData.Kind, threshold: int = 0, unlock_id: StringName = &"x") -> ChallengeData:
	var challenge := ChallengeData.new()
	challenge.id = StringName("c_%d_%d" % [kind, threshold])
	challenge.kind = kind
	challenge.threshold = threshold
	challenge.unlock_category = &"items"
	challenge.unlock_id = unlock_id
	return challenge


func test_profile_round_trip_and_empty_dict() -> void:
	var profile := Profile.new()
	profile.unlock(&"characters", &"ronin")
	profile.total_kills = 42
	profile.wins_by_character[&"drifter"] = 2
	profile.completed.append(&"win_drifter")
	var back := Profile.from_dict(JSON.parse_string(JSON.stringify(profile.to_dict())))
	assert_true(back.is_unlocked(&"characters", &"ronin"))
	assert_eq(back.total_kills, 42)
	assert_eq(back.wins_by_character.get(&"drifter", 0), 2)
	assert_true(back.completed.has(&"win_drifter"))
	var empty := Profile.from_dict({})
	assert_eq(empty.total_kills, 0)
	assert_false(empty.is_unlocked(&"characters", &"ronin"))


func test_profile_ignores_bad_types() -> void:
	var profile := Profile.from_dict({"total_kills": "lots", "unlocked": 3, "best_wave": 7.0})
	assert_eq(profile.total_kills, 0)
	assert_eq(profile.best_wave, 7)


func test_challenge_conditions() -> void:
	var profile := Profile.new()
	var result := _result(true, 20, 300)
	var win_with := _challenge(ChallengeData.Kind.WIN_WITH)
	win_with.character_id = &"ronin"
	assert_false(win_with.is_met(profile, result))
	result.character_id = &"ronin"
	assert_true(win_with.is_met(profile, result))
	profile.total_kills = 1999
	var kills := _challenge(ChallengeData.Kind.TOTAL_KILLS, 2000)
	assert_false(kills.is_met(profile, result))
	profile.total_kills = 2000
	assert_true(kills.is_met(profile, result))
	assert_true(_challenge(ChallengeData.Kind.REACH_WAVE, 20).is_met(profile, result))
	result.max_materials = 299
	assert_false(_challenge(ChallengeData.Kind.MATERIALS_HELD, 300).is_met(profile, result))
	var boss := _challenge(ChallengeData.Kind.KILL_ENEMY)
	boss.enemy_id = &"ronin"
	assert_false(boss.is_met(profile, result))
	result.killed_special.append(&"ronin")
	assert_true(boss.is_met(profile, result))


func test_record_run_updates_stats_unlocks_once_and_saves() -> void:
	var challenges: Array[ChallengeData] = [_challenge(ChallengeData.Kind.WIN_ANY, 0, &"reward_item")]
	var first := SaveService.record_run(_result(false, 8, 120), challenges)
	assert_eq(first.size(), 0)
	assert_eq(SaveService.profile.runs_played, 1)
	assert_eq(SaveService.profile.best_wave, 8)
	var second := SaveService.record_run(_result(true, 20, 500), challenges)
	assert_eq(second.size(), 1)
	assert_true(SaveService.profile.is_unlocked(&"items", &"reward_item"))
	assert_eq(SaveService.profile.total_kills, 620)
	assert_eq(SaveService.record_run(_result(true, 20, 10), challenges).size(), 0, "never twice")
	SaveService.load_profile()
	assert_eq(SaveService.profile.runs_won, 2)
	assert_true(SaveService.profile.is_unlocked(&"items", &"reward_item"))


func test_locked_content_needs_an_unlock() -> void:
	var item := ItemData.new()
	item.id = &"secret"
	assert_true(SaveService.is_unlocked(&"items", item), "unlocked by default")
	item.locked = true
	assert_false(SaveService.is_unlocked(&"items", item))
	SaveService.profile.unlock(&"items", &"secret")
	assert_true(SaveService.is_unlocked(&"items", item))
