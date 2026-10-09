extends GutTest
## Backgrounds of the character select screens: unlocked by winning a danger, chosen in the settings.

var _saved_setting: String


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()
	_saved_setting = Settings.data.select_background


func after_each() -> void:
	Settings.data.select_background = _saved_setting
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func _win(level: int) -> void:
	SaveService.profile.record_danger_win(level)


func test_no_danger_background_before_any_win() -> void:
	assert_eq(SelectBackdrops.unlocked_levels(), [] as Array[int])
	assert_eq(SelectBackdrops.resolve("danger_0"), -1, "a locked picture shows the hall")


func test_only_winning_that_very_danger_unlocks_its_background() -> void:
	_win(2)
	assert_eq(SelectBackdrops.unlocked_levels(), [2] as Array[int], "no picture for the levels below")
	assert_eq(SelectBackdrops.resolve("danger_2"), 2)
	assert_eq(SelectBackdrops.resolve("danger_1"), -1, "danger 2 is not won")
	assert_eq(SelectBackdrops.resolve("danger_3"), -1, "danger 4 is not won")


func test_a_won_run_records_its_danger() -> void:
	var result := RunResult.new()
	result.won = true
	result.difficulty = 3
	result.character_id = &"hero"
	SaveService.record_run(result, [] as Array[ChallengeData])
	assert_true(SaveService.profile.has_won_danger(3))
	assert_false(SaveService.profile.has_won_danger(2), "winning danger 4 does not win danger 3")


func test_won_dangers_are_saved_and_an_old_profile_is_converted() -> void:
	var profile := Profile.new()
	profile.record_danger_win(4)
	profile.record_danger_win(1)
	var back := Profile.from_dict(profile.to_dict())
	assert_eq(back.won_dangers, [1, 4] as Array[int])
	var old := Profile.from_dict({"best_difficulty_by_character": {"hero": 2}})
	assert_eq(old.won_dangers, [0, 1, 2] as Array[int], "an older save: each level up to the best was won in turn")


func test_default_setting_is_the_hall() -> void:
	_win(5)
	assert_eq(SelectBackdrops.resolve("default"), -1)


func test_random_draws_among_the_hall_and_the_unlocked_ones() -> void:
	_win(0)
	_win(2)
	assert_eq(SelectBackdrops.resolve("random", 0.0), -1, "first of the pool: the hall")
	assert_eq(SelectBackdrops.resolve("random", 0.4), 0)
	assert_eq(SelectBackdrops.resolve("random", 0.99), 2)
	for i in 50:
		assert_true(SelectBackdrops.resolve("random") in [-1, 0, 2], "never a locked picture")


func test_every_danger_has_a_picture() -> void:
	assert_eq(SelectBackdrops.DANGERS.size(), SelectBackdrops.DANGER_COUNT)
	assert_eq(SelectBackdrops.SOLO_DANGERS.size(), SelectBackdrops.DANGER_COUNT)
	for texture in SelectBackdrops.DANGERS + SelectBackdrops.SOLO_DANGERS:
		assert_not_null(texture)


func test_setting_accepts_only_known_values() -> void:
	var data := SettingsData.new()
	assert_eq(data.select_background, "default")
	assert_true(data.set_value(&"select_background", "danger_3"))
	assert_eq(data.select_background, "danger_3")
	data.set_value(&"select_background", "danger_9")
	assert_eq(data.select_background, "default", "an unknown value falls back to the hall")
	assert_false(data.set_value(&"select_background", 3), "wrong type refused")
	data.set_value(&"select_background", "random")
	assert_eq(SettingsData.from_dict(data.to_dict()).select_background, "random", "saved and read back")


func test_settings_list_locks_the_dangers_not_won() -> void:
	_win(0)
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.open()
	var items: Array[Button] = screen._background.items()
	assert_eq(items.size(), SettingsData.background_ids().size())
	assert_false(items[1].disabled, "danger 1 is won")
	assert_true(items[2].disabled, "danger 2 is not")
	assert_eq(SettingsData.background_ids().back(), "random", "random comes last")


func test_solo_screen_shows_the_chosen_background() -> void:
	_win(3)
	Settings.data.select_background = "danger_3"
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	assert_eq(screen._backdrop.texture, SelectBackdrops.SOLO_DANGERS[3])
	assert_false(screen._hotspots.visible, "the painted flames are off until they are redone")
	Settings.data.select_background = "default"
	screen.open()
	assert_eq(screen._backdrop.texture, SelectBackdrops.SOLO_HALL)
	assert_false(screen._hotspots.visible)


func test_coop_screen_shows_the_chosen_background() -> void:
	_win(1)
	Settings.data.select_background = "danger_1"
	var screen := CoopCharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	assert_eq(screen._backdrop.texture, SelectBackdrops.DANGERS[1])
	Settings.data.select_background = "default"
	screen.open()
	assert_eq(screen._backdrop.texture, SelectBackdrops.HALL)


func test_solo_picker_changes_the_background_at_once() -> void:
	_win(1)
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	assert_not_null(screen._picker, "top right of the solo screen")
	assert_false(screen._title.visible, "no title any more")
	screen._picker.toggle()
	assert_true(screen._picker.is_open(), "the row of pictures opens")
	screen._picker.items()[2].pressed.emit()
	assert_eq(Settings.data.select_background, "danger_1")
	assert_false(screen._picker.is_open(), "and closes once one is picked")
	assert_eq(screen._backdrop.texture, SelectBackdrops.SOLO_DANGERS[1])


func test_coop_up_and_down_cycle_the_unlocked_backgrounds() -> void:
	_win(0)
	_win(3)
	Settings.data.select_background = "default"
	var screen := CoopCharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	screen.press(0, &"ui_down")
	assert_eq(Settings.data.select_background, "danger_0")
	screen.press(0, &"ui_down")
	assert_eq(Settings.data.select_background, "danger_3", "locked ones are skipped")
	screen.press(0, &"ui_down")
	assert_eq(Settings.data.select_background, "random", "random is the last of the row")
	screen.press(0, &"ui_up")
	assert_eq(Settings.data.select_background, "danger_3")


func test_block_is_hall_and_random_then_dangers_in_two_lines_of_three() -> void:
	var picker := BackdropPicker.new()
	add_child_autofree(picker)
	picker.refresh()
	var ids := SettingsData.background_ids()
	var shown: Array[String] = []
	for index in BackdropPicker.BLOCK_ORDER:
		shown.append(ids[index])
	assert_eq(shown, ["default", "danger_0", "danger_1", "danger_2", "random", "danger_3", "danger_4", "danger_5"] as Array[String])
	assert_eq(picker._row.columns, 4)
	assert_eq(picker._row.get_theme_constant("h_separation"), 0, "stuck together")


func test_row_of_pictures_is_in_unlock_order() -> void:
	_win(0)
	var picker := BackdropPicker.new()
	add_child_autofree(picker)
	picker.refresh()
	var items := picker.items()
	assert_eq(items.size(), 8, "hall, six dangers, random")
	assert_false(items[0].disabled)
	assert_false(items[1].disabled, "danger 1 won")
	for index in range(2, 7):
		assert_true(items[index].disabled, "danger %d locked" % index)
	assert_false(items[7].disabled, "random always on offer")


func test_every_picture_has_the_same_zoom_in_a_given_mode() -> void:
	_win(0)
	_win(4)
	for coop in [false, true]:
		var zooms := []
		for setting in ["default", "danger_0", "danger_4"]:
			Settings.data.select_background = setting
			var backdrop := UiBackdrop.new()
			add_child_autofree(backdrop)
			SelectBackdrops.apply(backdrop, coop)
			zooms.append([backdrop.base_zoom, backdrop.shift])
		assert_eq(zooms[1], zooms[0], "danger 1 like the hall (coop: %s)" % coop)
		assert_eq(zooms[2], zooms[0], "danger 5 like the hall (coop: %s)" % coop)
		assert_eq(zooms[0][0], 1.0, "a picture is shown as it is, never cropped by a zoom")


func test_interface_takes_the_hue_of_the_background() -> void:
	_win(3)
	Settings.data.select_background = "danger_3"
	var screen := CoopCharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	assert_eq(SelectBackdrops.hue, SelectBackdrops.DANGER_HUES[3])
	assert_eq(screen.theme, UiTheme.get_theme(SelectBackdrops.hue))
	assert_ne(screen.theme, UiTheme.get_theme(0.0), "not the blue theme")
	var blue := UiTheme.frame_texture("panel_cyan").get_image()
	var red := UiTheme.frame_texture("panel_cyan", SelectBackdrops.hue).get_image()
	var changed := 0
	for y in blue.get_height():
		for x in blue.get_width():
			if blue.get_pixel(x, y).h != red.get_pixel(x, y).h and blue.get_pixel(x, y).a > 0.5:
				changed += 1
	assert_gt(changed, 100, "the blue lines of the frame turned")
	Settings.data.select_background = "default"
	screen.open()
	assert_eq(SelectBackdrops.hue, 0.0, "the hall keeps the blue interface")


func test_interface_fills_follow_the_background_too() -> void:
	var blue := UiTheme.frame_texture("card").get_image()
	var shifted := UiTheme.frame_texture("card", -195.0).get_image()
	var moved := 0
	for y in blue.get_height():
		for x in blue.get_width():
			if blue.get_pixel(x, y).a > 0.5 and not is_equal_approx(blue.get_pixel(x, y).h, shifted.get_pixel(x, y).h):
				moved += 1
	assert_gt(moved, 500, "the dark blue inside the white frames turned as well")


func test_upgrade_that_adds_attacks_is_not_called_after_arrows() -> void:
	var upgrade := ContentDB.get_def(&"upgrades", &"multishot") as UpgradeData
	TranslationServer.set_locale("en")
	assert_eq(tr(upgrade.name_key), "Multi-attack", "melee weapons strike more often too, not only shoot")
	TranslationServer.set_locale("fr")
	assert_eq(tr(upgrade.name_key), "Attaque multiple")
	TranslationServer.set_locale("en")


func test_select_pictures_are_shown_whole_never_cut() -> void:
	# Regression (dev, 2026-10-09): the 3:2 pictures were "covered" on a 16:9 screen, which cut their top
	# (the dragon's skull) and bottom (the floor of the seals). The whole picture is shown now.
	Settings.data.select_background = "default"
	var backdrop := UiBackdrop.new()
	backdrop.animated = false
	add_child_autofree(backdrop)
	backdrop.set_anchors_preset(Control.PRESET_TOP_LEFT)
	backdrop.size = Vector2(1920.0, 1080.0)
	SelectBackdrops.apply(backdrop, false)
	await wait_process_frames(2)
	assert_true(backdrop.fit_height)
	assert_almost_eq(backdrop._picture_rect.position.y, 0.0, 0.01)
	assert_almost_eq(backdrop._picture_rect.size.y, 1080.0, 0.01, "the whole height of the picture")
	assert_lt(backdrop._picture_rect.size.x, 1920.0, "the sides are filled by mirrored copies, not by a crop")


func test_the_last_portal_rumbles_while_it_is_pointed_and_never_under_another_screen() -> void:
	_win(5)
	var seals := SealSelect.new()
	add_child_autofree(seals)
	var hunters: Array[CharacterData] = [ContentDB.get_all(&"characters")[0]]
	seals.open(hunters)
	seals._point(5)
	assert_true(Audio._loops.has(SealSelect.RUMBLE_LOOP) and (Audio._loops[SealSelect.RUMBLE_LOOP] as AudioStreamPlayer).playing, "rumble on the last seal")
	seals._point(0)
	await wait_seconds(0.6)
	assert_false((Audio._loops[SealSelect.RUMBLE_LOOP] as AudioStreamPlayer).playing, "silent on the others")
	seals._point(5)
	seals.close()
	await wait_seconds(0.6)
	assert_false((Audio._loops[SealSelect.RUMBLE_LOOP] as AudioStreamPlayer).playing, "silent once the screen is closed")


func test_the_seal_screen_has_no_title() -> void:
	var seals := SealSelect.new()
	add_child_autofree(seals)
	for label in seals.find_children("*", "Label", true, false):
		assert_ne((label as Label).text, "UI_CHOOSE_DANGER")


func test_health_bar_is_a_vivid_red() -> void:
	assert_gt(UiTheme.HEALTH_RED.r, 0.95)
	assert_lt(UiTheme.HEALTH_RED.g, 0.2)


func test_a_click_on_the_hero_validates_the_class_then_the_look() -> void:
	# Dev's request, 2026-10-10: in coop, as in solo, the hero itself can be clicked.
	var screen := CoopCharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	screen.cursor_to(0, &"hero")
	screen._hero_hit[0].pressed.emit()
	assert_eq(screen.step_of(0), CoopCharacterSelect.Step.LOOK, "the class is locked")
	screen._hero_hit[0].pressed.emit()
	assert_eq(screen.step_of(0), CoopCharacterSelect.Step.WEAPON, "the look is validated")
	assert_eq(screen.step_of(1), CoopCharacterSelect.Step.LIST, "the other hunter is not touched")


func test_coop_class_bar_is_at_the_bottom_of_the_screen() -> void:
	var screen := CoopCharacterSelect.new()
	add_child_autofree(screen)
	assert_eq(screen._bar.anchor_top, 1.0, "anchored at the bottom: the portals of the pictures stay visible")


func test_each_portal_has_the_color_of_its_place() -> void:
	assert_eq(SealSelect.PORTAL_COLORS.size(), 6)
	var forest := SealSelect.PORTAL_COLORS[2]
	assert_gt(forest.r, 0.85, "the frozen forest portal is white")
	assert_gt(forest.b, 0.85)
	var hive := SealSelect.PORTAL_COLORS[4]
	assert_gt(hive.g, hive.r * 1.5, "the hive portal is green")
	assert_gt(hive.g, hive.b * 1.5)


func test_seal_screen_shows_the_whole_gate_and_a_calm_play_button() -> void:
	var seals := SealSelect.new()
	add_child_autofree(seals)
	seals.set_anchors_preset(Control.PRESET_TOP_LEFT)
	seals.size = Vector2(1920.0, 1080.0)
	var drawn := seals._drawn()
	assert_almost_eq(drawn.y, 1080.0, 0.01, "the picture is as tall as the screen: nothing cut")
	assert_lt(drawn.x, 1920.0)
	assert_ne(seals._launch.theme_type_variation, &"CtaButton", "not the bright main-action button")


func test_the_mouse_over_a_weapon_moves_the_hunters_cursor() -> void:
	# Regression (dev, 2026-10-10): after a click validated the class, hovering the weapons did nothing.
	var screen := CoopCharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	screen.cursor_to(0, &"hero")
	screen._hero_hit[0].pressed.emit()
	screen._hero_hit[0].pressed.emit()
	assert_eq(screen.step_of(0), CoopCharacterSelect.Step.WEAPON)
	assert_eq(screen._weapon_index[0], 0)
	(screen._weapon_box[0].get_child(1) as Button).mouse_entered.emit()
	await wait_process_frames(2)
	assert_eq(screen._weapon_index[0], 1, "the cursor follows the mouse")


func test_stat_bars_are_as_tall_as_their_frame() -> void:
	# Regression (dev, 2026-10-10): at 20 px the slanted ends of the 28 px frame came out broken.
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	for bar in screen._hero_bars.values():
		assert_gte((bar as ProgressBar).custom_minimum_size.y, 28.0)
