extends GutTest
## Seal screen (SealSelect): the six seals, effects, places to come, locks, rewards.

var _chosen: DifficultyData


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()
	_chosen = null


func after_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func _open(ids: Array[StringName]) -> SealSelect:
	var screen := SealSelect.new()
	add_child_autofree(screen)
	screen.chosen.connect(func(difficulty: DifficultyData) -> void: _chosen = difficulty)
	var hunters: Array[CharacterData] = []
	for id in ids:
		hunters.append(ContentDB.get_def(&"characters", id) as CharacterData)
	screen.open(hunters)
	return screen


func test_effects_stack_and_places_are_named() -> void:
	var levels := SealSelect.all_levels()
	assert_string_contains(SealSelect.seal_effects(levels[0]), tr("SEAL_FX_NONE"))
	assert_eq(SealSelect.seal_place(levels[0], levels), tr("BIOME_DUNGEON"))
	assert_eq(SealSelect.seal_place(levels[1], levels), tr("BIOME_TEMPLE"))
	var astral := SealSelect.seal_effects(levels[5])
	assert_string_contains(astral, tr("SEAL_FX_DOUBLE_BOSS"))
	assert_string_contains(astral, tr("SEAL_FX_HP_DAMAGE") % roundi((levels[5].hp_multiplier - 1.0) * 100.0))


func test_seal_reusing_a_lower_place_says_place_to_come() -> void:
	var levels := SealSelect.all_levels()
	for difficulty in levels:
		var shared := false
		for other in levels:
			shared = shared or (other.level < difficulty.level and other.biome == difficulty.biome)
		var place := SealSelect.seal_place(difficulty, levels)
		assert_eq(place == tr("SEAL_PLACE_COMING"), shared, String(difficulty.id))


func test_six_seals_the_locked_ones_marked() -> void:
	var screen := _open([&"drifter"])
	var buttons := screen.seal_buttons()
	assert_eq(buttons.size(), 6)
	assert_false(buttons[0].get_meta(&"locked"))
	assert_true(buttons[5].get_meta(&"locked"))
	assert_eq(screen.chosen_difficulty().level, 0, "the hardest open seal is picked")
	assert_string_contains(screen._name.text, tr("DANGER_0"))


func test_a_locked_seal_shows_its_info_but_is_not_picked() -> void:
	var screen := _open([&"drifter"])
	var locked := screen.seal_buttons()[5]
	assert_false(locked.disabled, "not disabled: it can be hovered")
	locked.grab_focus()
	assert_string_contains(screen._name.text, tr("DANGER_5"))
	assert_string_contains(screen._place.text, tr("SEAL_LOCKED_HINT"))
	assert_eq(screen.chosen_difficulty().level, 0, "the seal to play does not change")
	locked.pressed.emit()
	assert_null(_chosen, "pressing a locked seal starts nothing")


func test_pressing_a_seal_moves_to_play_and_play_confirms_it() -> void:
	var screen := _open([&"drifter"])
	screen.seal_buttons()[0].pressed.emit()
	assert_null(_chosen, "a seal press never launches")
	assert_true(screen._launch.has_focus())
	screen._launch.pressed.emit()
	assert_eq(_chosen.level, 0)


func test_a_seal_is_open_only_when_every_hunter_won_the_one_below() -> void:
	SaveService.profile.best_difficulty_by_character[&"drifter"] = 1
	assert_eq(SealSelect.allowed_level([ContentDB.get_def(&"characters", &"drifter")] as Array[CharacterData]), 2)
	var screen := _open([&"drifter", &"hero"])
	assert_true(screen.seal_buttons()[1].get_meta(&"locked"), "the other hunter has not won Copper")
	assert_eq(screen.chosen_difficulty().level, 0)


func test_rewards_to_win_are_silhouettes() -> void:
	var screen := _open([&"drifter"])
	assert_eq(screen._rewards.get_child_count(), SealSelect.seal_rewards(0).size())
	assert_eq(screen._rewards_title.text, tr("SEAL_TO_WIN"))
	var art := screen._rewards.get_child(0).get_child(0) as TextureRect
	assert_eq(art.material, SealSelect.silhouette_material())
