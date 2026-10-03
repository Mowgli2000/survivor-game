extends GutTest
## Characters, run setup, locked content filtering and run recording (ADR 0015).

const RUN := preload("res://src/run/run.tscn")


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.TEST_PATH))
	SaveService.load_profile()


func _setup(character: StringName, weapon: StringName) -> RunSetup:
	var setup := RunSetup.new()
	setup.character = ContentDB.get_def(&"characters", character)
	setup.weapon = ContentDB.get_def(&"weapons", weapon)
	return setup


func _run(setup: RunSetup) -> Run:
	var run: Run = RUN.instantiate()
	run.seed_override = 2
	run.setup = setup
	add_child_autofree(run)
	return run


func test_character_modifiers_and_chosen_weapon_apply() -> void:
	var run := _run(_setup(&"ronin", &"shuriken"))
	assert_eq(run.player.weapons.get_slots()[0].data.id, &"shuriken")
	assert_gt(run.player.stats.get_value(StatIds.CRIT_CHANCE), StatIds.DEFAULTS[StatIds.CRIT_CHANCE])
	assert_lt(run.player.stats.get_value(StatIds.RANGE), 1.0, "Ronin malus: less range")


func test_merchant_rule_effects_are_active() -> void:
	var run := _run(_setup(&"merchant", &"pulse"))
	assert_gt(run.item_effects.effect_count(), 0, "interest rule")


func test_locked_items_never_reach_the_shop_pool() -> void:
	var run := _run(null)
	for item in run.shop._item_pool:
		assert_false(item.locked and not SaveService.profile.is_unlocked(&"items", item.id),
			"%s is locked" % item.id)
	SaveService.profile.unlock(&"items", &"glass_cannon")
	var run2 := _run(null)
	assert_true(run2.shop._item_pool.has(ContentDB.get_def(&"items", &"glass_cannon")))


func test_a_menu_run_is_recorded_when_it_ends() -> void:
	var run := _run(_setup(&"drifter", &"pulse"))
	run.state.kills = 2100
	run.player.invincible = false
	run.player.take_damage(1e9)
	assert_eq(SaveService.profile.runs_played, 1)
	assert_true(SaveService.profile.is_unlocked(&"characters", &"gunslinger"), "2 000 kills challenge")
	assert_string_contains(run.game_over_screen._unlocks.text, tr("CHARACTER_GUNSLINGER"))


func test_runs_without_setup_are_not_recorded() -> void:
	var run := _run(null)
	run.player.invincible = false
	run.player.take_damage(1e9)
	assert_eq(SaveService.profile.runs_played, 0, "tests and debug tools stay out of the profile")


func test_character_select_flow() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	assert_true(screen._character_buttons[&"ronin"].disabled, "locked character")
	assert_false(screen._character_buttons[&"drifter"].disabled)
	watch_signals(screen)
	screen._character_buttons[&"drifter"].pressed.emit()
	assert_true(screen._weapons.visible)
	var first: Button = screen._weapons.get_child(0)
	first.pressed.emit()
	assert_signal_emitted(screen, "started")
	var setup: RunSetup = get_signal_parameters(screen, "started")[0]
	assert_eq(setup.character.id, &"drifter")
	assert_not_null(setup.weapon)


func test_progression_screen_lists_every_challenge() -> void:
	var screen := ProgressionScreen.new()
	add_child_autofree(screen)
	screen.open()
	assert_eq(screen._rows.get_child_count(), SaveService.all_challenges().size())
