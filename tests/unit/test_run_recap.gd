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


func test_end_screen_shows_the_recap() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	screen.open(60.0, 5, 100, 4)
	screen.show_recap(GameOverScreen.recap_rows({&"katana": 120.0}), 30.0)
	assert_true(screen._recap.visible)
	assert_string_contains(screen._summary.text, "30")
