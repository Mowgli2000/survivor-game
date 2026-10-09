extends GutTest
## Screens drawn with the shared UI theme (UiTheme): tier-colored cards, titles.


func test_level_up_cards_use_the_themed_card_style() -> void:
	var screen := LevelUpScreen.new()
	add_child_autofree(screen)
	var upgrade: UpgradeData = ContentDB.get_all(&"upgrades")[0]
	var offers: Array[UpgradeOffer] = [UpgradeOffer.for_stat(upgrade, 3)]
	screen.open(offers)
	var card := screen._cards.get_child(0) as Button
	var style := card.get_theme_stylebox("normal") as StyleBoxTexture
	assert_eq(style.texture, UiTheme.frame_texture("card"), "baked card frame")
	assert_eq(Color(style.modulate_color, 1.0), Color(UiTheme.frame_tint(Tiers.color(3), 0.6), 1.0), "tier tint")


func test_game_over_title_is_gold_on_victory() -> void:
	var screen := GameOverScreen.new()
	add_child_autofree(screen)
	screen.open(60.0, 5, 100, 20, true)
	assert_eq(screen._title.theme_type_variation, &"TitleLabel")
	assert_eq(screen._title.get_theme_color("font_color"), UiTheme.GOLD)
	screen.open(60.0, 5, 100, 3, false)
	assert_eq(screen._title.get_theme_color("font_color"), UiTheme.BAD)


func test_wave_end_title_uses_the_title_style() -> void:
	var screen := WaveEndScreen.new()
	add_child_autofree(screen)
	screen.open(3)
	assert_eq(screen._title.theme_type_variation, &"TitleLabel")
