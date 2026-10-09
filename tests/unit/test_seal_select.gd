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


func test_a_seal_won_by_any_hunter_is_open_for_the_whole_party() -> void:
	SaveService.profile.best_difficulty_by_character[&"drifter"] = 1
	assert_eq(SealSelect.allowed_level([ContentDB.get_def(&"characters", &"drifter")] as Array[CharacterData]), 2)
	var screen := _open([&"drifter", &"hero"])
	assert_false(screen.seal_buttons()[2].get_meta(&"locked"), "the party's best win opens Silver for both")
	assert_true(screen.seal_buttons()[3].get_meta(&"locked"))


func test_rewards_to_win_are_silhouettes() -> void:
	var screen := _open([&"drifter"])
	assert_eq(screen._rewards.get_child_count(), SealSelect.seal_rewards(0).size())
	assert_eq(screen._rewards_title.text, tr("SEAL_TO_WIN"))
	var art := screen._rewards.get_child(0).get_child(0) as TextureRect
	assert_eq(art.material, SealSelect.silhouette_material())


func test_plaques_climb_in_two_mirrored_columns_with_the_last_seal_lowest_on_the_right() -> void:
	var screen := _open([&"drifter"])
	await wait_frames(3)
	var buttons := screen.seal_buttons()
	# Left: I at the bottom; right: VI at the bottom, IV at the top.
	assert_gt(buttons[0].position.y, buttons[2].position.y, "I is below III")
	assert_gt(buttons[5].position.y, buttons[3].position.y, "VI is below IV")
	for i in 3:
		var left := buttons[i]
		var right := buttons[5 - i]
		assert_almost_eq(left.position.y, right.position.y, 12.0, "same row (painted by hand: a few px apart)")
		assert_eq(left.find_valid_focus_neighbor(SIDE_RIGHT), right, "right from seal %d" % i)
		assert_eq(right.find_valid_focus_neighbor(SIDE_LEFT), left, "left from seal %d" % (5 - i))
		var mirror := (left.position.x + left.size.x * 0.5) + (right.position.x + right.size.x * 0.5)
		# The medallions are painted in the picture (symmetric to a few px, not to the pixel).
		assert_almost_eq(mirror * 0.5, screen._picture_to_screen(SealSelect.PORTAL_CENTER).x, 12.0, "mirrored on the portal")


func test_each_seal_has_its_own_portal_color_and_the_last_is_red() -> void:
	var levels := SealSelect.all_levels()
	var seen := {}
	for difficulty in levels:
		seen[difficulty.color.to_html()] = true
	assert_eq(seen.size(), levels.size(), "six different colors")
	var last := levels[levels.size() - 1].color
	assert_gt(last.r, 0.9)
	assert_lt(last.g, 0.3)
	assert_lt(last.b, 0.3)


func test_hidden_weapons_cannot_take_the_focus_behind_the_seals() -> void:
	# Playtest: right from Obsidian went onto a weapon card hidden behind the seal screen.
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	screen._character_buttons[&"drifter"].pressed.emit()
	(screen._weapons.get_child(0) as Button).pressed.emit()
	screen._next.pressed.emit()
	assert_true(screen._seals.visible)
	assert_false((screen._weapons.get_child(0) as Control).is_visible_in_tree())
	assert_false(screen._next.is_visible_in_tree())
	screen._seals._go_back()
	assert_true(screen._next.is_visible_in_tree(), "back: the weapons are there again")
