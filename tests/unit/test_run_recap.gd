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
