extends GutTest
## End-of-run damage summary (GameOverScreen.recap_rows / show_recap).


func test_rows_are_sorted_and_named() -> void:
	var rows := GameOverScreen.recap_rows({&"katana": 120.0, EnemyManager.BURN_TAG: 300.0,
		EnemyManager.ITEMS_TAG: 50.0, &"unknown_weapon": 999.0, &"bomb": 0.0})
	assert_eq(rows.size(), 3, "unknown ids and zero damage dropped")
	assert_eq(rows[0].name, "UI_RECAP_BURN")
	assert_eq(rows[1].name, (ContentDB.get_def(&"weapons", &"katana") as WeaponData).name_key)
	assert_not_null(rows[1].icon)
	assert_eq(rows[2].name, "UI_RECAP_ITEMS")


func test_compact_numbers() -> void:
	assert_eq(GameOverScreen.compact(950.0), "950")
	assert_eq(GameOverScreen.compact(12345.0), "12.3k")
	assert_eq(GameOverScreen.compact(4500000.0), "4.5M")


func test_end_screen_shows_one_column_per_player() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	screen.open(60.0, 5, 100, 4)
	var columns: Array[Dictionary] = [
		{"title": "Player 1", "color": Color.CYAN, "rows": GameOverScreen.recap_rows({&"katana": 120.0})},
		{"title": "Player 2", "color": Color.ORANGE, "rows": GameOverScreen.recap_rows({&"bomb": 80.0})},
	]
	screen.show_recap(columns)
	assert_true(screen._recap.visible)
	assert_eq(screen._recap.get_child_count(), 2)


func test_coop_columns_show_each_players_kills_and_deaths() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	var rows: Array[Dictionary] = []
	screen.show_recap([
		{"title": "Player 1", "color": Color.WHITE, "rows": rows, "kills": 120, "deaths": 2},
		{"title": "Player 2", "color": Color.WHITE, "rows": rows, "kills": 80, "deaths": 0}])
	assert_eq(screen._recap.get_child_count(), 2, "a column per player even without damage rows")


func test_final_weapons_come_first_even_when_others_dealt_more() -> void:
	var final_ids: Array[StringName] = [&"katana"]
	var rows := GameOverScreen.recap_rows({&"katana": 120.0, &"bomb": 900.0, EnemyManager.BURN_TAG: 300.0}, final_ids)
	assert_eq(rows.size(), 3)
	assert_eq(rows[0].name, (ContentDB.get_def(&"weapons", &"katana") as WeaponData).name_key, "held at the end: first")
	assert_true(rows[0].final)
	assert_eq(rows[1].name, (ContentDB.get_def(&"weapons", &"bomb") as WeaponData).name_key, "then the others by damage")
	assert_false(rows[1].final)


func test_long_list_scrolls_and_shows_six_rows_first() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	screen.open(60.0, 5, 100, 4)
	var dealt := {}
	var final_ids: Array[StringName] = []
	var weapons: Array = ContentDB.get_all(&"weapons")
	for i in 9:
		var weapon: WeaponData = weapons[i]
		dealt[weapon.id] = 100.0 + i
		if i < 6:
			final_ids.append(weapon.id)
	screen.show_recap([{"title": "", "color": Color.WHITE, "rows": GameOverScreen.recap_rows(dealt, final_ids)}])
	assert_eq(screen._recap_scrolls.size(), 1, "9 weapons: the list scrolls")
	var list: Node = screen._recap_scrolls[0].get_child(0)
	assert_eq(list.get_child_count(), 10, "9 rows and a divider")
	assert_eq((list.get_child(6) as Label).text, "UI_RECAP_OTHERS", "divider right after the six final weapons")


func test_short_list_does_not_scroll() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	screen.open(60.0, 5, 100, 4)
	var final_ids: Array[StringName] = [&"katana"]
	screen.show_recap([{"title": "", "color": Color.WHITE,
		"rows": GameOverScreen.recap_rows({&"katana": 120.0, &"bomb": 80.0}, final_ids)}])
	assert_true(screen._recap_scrolls.is_empty())


func test_a_victory_shows_the_unlocks_alone_before_the_statistics() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	screen.open(120.0, 10, 50, 20, true)
	var challenges: Array[ChallengeData] = [ContentDB.get_def(&"challenges", &"win_drifter")]
	screen.show_unlocks(challenges)
	assert_true(screen.is_revealing(), "the unlocks come first")
	assert_false(screen._middle.visible, "no statistics yet")
	assert_false(screen._buttons.visible)
	assert_true(screen._continue.visible)
	screen._continue.pressed.emit()
	assert_false(screen.is_revealing())
	assert_true(screen._middle.visible, "now the statistics")
	assert_true(screen._buttons.visible)
	assert_false(screen._unlocks.visible, "the cards were seen")


func test_a_defeat_or_a_victory_without_unlocks_goes_straight_to_the_statistics() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	screen.open(120.0, 10, 50, 20, true)
	screen.show_unlocks([])
	assert_false(screen.is_revealing())
	assert_true(screen._middle.visible)
	screen.open(60.0, 5, 10, 8, false)
	var challenges: Array[ChallengeData] = [ContentDB.get_def(&"challenges", &"win_drifter")]
	screen.show_unlocks(challenges)
	assert_false(screen.is_revealing(), "a defeat shows the cards with the statistics")


func test_the_victory_screen_lists_the_chest_rewards_with_their_description_on_hover() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	screen.open(100.0, 10, 40, 20, true)
	var item: ItemData = ContentDB.get_all(&"items")[0]
	var rewards: Array[Dictionary] = [{"item": item, "title": "", "color": Color.WHITE}]
	screen.show_rewards(rewards)
	assert_eq(screen.reward_icon_count(), 1)
	assert_true(screen._rewards_box.visible)
	assert_eq(screen._reward_text.text, "")
	(screen._rewards_row.get_child(0) as Button).focus_entered.emit()
	assert_ne(screen._reward_text.text, "", "the description shows on focus")
	screen.show_rewards([])
	assert_false(screen._rewards_box.visible, "no chest, no recap")


func test_a_new_danger_win_shows_a_background_card() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	screen.open(120.0, 10, 50, 20, true)
	screen.show_unlocks([], [2] as Array[int])
	assert_eq(screen.unlock_names(), PackedStringArray(["UI_UNLOCK_BACKDROP"]), "one card for the background")
	assert_true(screen.is_revealing(), "shown alone before the statistics")
