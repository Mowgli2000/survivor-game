extends GutTest
## Seal row of the selection screen: numerals, effects line, places to come.


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func after_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func _levels() -> Array[DifficultyData]:
	var levels: Array[DifficultyData] = []
	levels.assign(ContentDB.get_all(&"difficulties"))
	levels.sort_custom(func(a: DifficultyData, b: DifficultyData) -> bool: return a.level < b.level)
	return levels


func test_heat_goes_from_cold_to_red() -> void:
	assert_gt(CharacterSelect.seal_heat(0).g, CharacterSelect.seal_heat(0).r, "Copper is green-blue")
	assert_gt(CharacterSelect.seal_heat(5).r, CharacterSelect.seal_heat(5).g, "Astral is red")
	assert_eq(CharacterSelect.seal_heat(99), CharacterSelect.seal_heat(5))


func test_info_lists_stacked_effects_and_place() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	var levels := _levels()
	var copper := screen._seal_info_text(levels[0], levels, true)
	assert_string_contains(copper, tr("BIOME_DUNGEON"))
	assert_string_contains(copper, tr("SEAL_FX_NONE"))
	var iron := screen._seal_info_text(levels[1], levels, true)
	assert_string_contains(iron, tr("BIOME_TEMPLE"))
	var astral := screen._seal_info_text(levels[5], levels, false)
	assert_string_contains(astral, tr("SEAL_FX_DOUBLE_BOSS"))
	assert_string_contains(astral, tr("SEAL_FX_HP_DAMAGE") % roundi((levels[5].hp_multiplier - 1.0) * 100.0))
	assert_string_contains(astral, tr("SEAL_LOCKED_HINT"))


func test_seal_reusing_a_lower_place_says_place_to_come() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	var levels := _levels()
	for difficulty in levels:
		var shared := false
		for other in levels:
			shared = shared or (other.level < difficulty.level and other.biome == difficulty.biome)
		var text := screen._seal_info_text(difficulty, levels, true)
		assert_eq(text.contains(tr("SEAL_PLACE_COMING")), shared, String(difficulty.id))


func test_locked_seals_are_disabled_and_show_the_row_info() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	screen._character_buttons[&"drifter"].pressed.emit()
	(screen._weapons.get_child(0) as Button).pressed.emit()
	assert_eq(screen._dangers.get_child_count(), 6)
	assert_false((screen._dangers.get_child(0) as Button).disabled)
	assert_true((screen._dangers.get_child(5) as Button).disabled)
	assert_true(screen._seal_info.visible)
	assert_string_contains(screen._seal_info.text, tr("DANGER_0"))
