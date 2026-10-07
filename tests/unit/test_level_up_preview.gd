extends GutTest
## Level-up cards show each changed stat as "current -> new".


func before_each() -> void:
	TranslationServer.set_locale("en")


func test_card_preview_shows_current_and_new_value() -> void:
	var stats := StatBlock.from_defaults({"max_hp": 100.0})
	var offer := UpgradeOffer.for_stat(ContentDB.get_def(&"upgrades", &"vitality"), 2)
	var lines := LevelUpScreen.preview_lines(offer, stats)
	assert_eq(lines.size(), 1)
	assert_eq(lines[0][0], "Max HP: 100 → 116")
	assert_true(lines[0][1], "an increase is shown as an improvement")
	assert_eq(stats.get_value(StatIds.MAX_HP), 100.0, "preview does not apply the card")


func test_reroll_shortcut_asks_for_a_reroll() -> void:
	var screen := LevelUpScreen.new()
	add_child_autofree(screen)
	var offers: Array[UpgradeOffer] = [UpgradeOffer.for_stat(ContentDB.get_def(&"upgrades", &"vitality"), 1)]
	screen.open(offers, 3, true)
	await wait_seconds(LevelUpScreen.INPUT_DELAY + 0.1)
	var asked := [false]
	screen.reroll_requested.connect(func() -> void: asked[0] = true)
	var event := InputEventAction.new()
	event.action = &"reroll"
	event.pressed = true
	screen._unhandled_input(event)
	assert_true(asked[0])
