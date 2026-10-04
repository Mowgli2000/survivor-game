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
	var run := _run(_setup(&"ronin", &"spear"))
	assert_eq(run.player.weapons.get_slots()[0].data.id, &"spear")
	assert_gt(run.player.stats.get_value(StatIds.DAMAGE), 1.0, "Swordswoman bonus: more damage")
	assert_lt(run.player.stats.get_value(StatIds.RANGE), 1.0, "Swordswoman malus: less range")


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
	assert_true(run.game_over_screen.unlock_names().has("CHARACTER_GUNSLINGER"), "unlock shown as a card")


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
	(screen._dangers.get_child(0) as Button).pressed.emit()
	assert_signal_emitted(screen, "started")
	var setup: RunSetup = get_signal_parameters(screen, "started")[0]
	assert_eq(setup.character.id, &"drifter")
	assert_not_null(setup.weapon)


func test_progression_screen_lists_every_challenge() -> void:
	var screen := ProgressionScreen.new()
	add_child_autofree(screen)
	screen.open()
	assert_eq(screen._rows.get_child_count(), SaveService.all_challenges().size())


func test_character_cards_show_the_card_illustration() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	screen.open()
	var arts := _find_arts(screen._character_buttons[&"drifter"])
	assert_eq(arts.size(), 1)
	assert_not_null(arts[0].texture, "drifter card art loaded")
	assert_eq(arts[0].modulate, Color.WHITE)
	assert_eq(_find_arts(screen._character_buttons[&"ronin"])[0].modulate, SpritePreview.SILHOUETTE,
		"locked = silhouette")


func test_character_without_card_art_shows_the_animated_sprite() -> void:
	var screen := CharacterSelect.new()
	add_child_autofree(screen)
	var character := CharacterData.new()
	character.sprite_id = &"drifter"
	var portrait := screen._portrait(character, true)
	autofree(portrait)
	var previews := _find_previews(portrait)
	assert_eq(previews.size(), 1)
	assert_true(previews[0].has_sheet(), "drifter sprite loaded")
	assert_false(previews[0].silhouette)


func _find_arts(node: Node) -> Array[TextureRect]:
	var found: Array[TextureRect] = []
	for child in node.get_children():
		if child is TextureRect:
			found.append(child)
		found.append_array(_find_arts(child))
	return found


func _find_previews(node: Node) -> Array[SpritePreview]:
	var found: Array[SpritePreview] = []
	for child in node.get_children():
		if child is SpritePreview:
			found.append(child)
		found.append_array(_find_previews(child))
	return found


# --- Class rules (docs/design/classes-proposition.md) --------------------------

func test_melee_and_ranged_classes_only_get_their_weapons() -> void:
	var swordswoman: CharacterData = ContentDB.get_def(&"characters", &"ronin")
	var archer: CharacterData = ContentDB.get_def(&"characters", &"gunslinger")
	var melee := 0
	for weapon: WeaponData in ContentDB.get_all(&"weapons"):
		assert_ne(swordswoman.allows_weapon(weapon), archer.allows_weapon(weapon), String(weapon.id))
		if weapon.is_melee():
			melee += 1
	assert_gte(melee, 3, "the melee-only class needs at least 3 melee weapons")


func test_starting_weapons_follow_the_class_rule() -> void:
	for character: CharacterData in ContentDB.get_all(&"characters"):
		for weapon in character.starting_weapons:
			assert_true(character.allows_weapon(weapon), "%s: %s" % [character.id, weapon.id])


func test_rank_e_hunter_cards_are_stronger() -> void:
	var hunter: CharacterData = ContentDB.get_def(&"characters", &"drifter")
	var offer := UpgradeOffer.for_stat(ContentDB.get_def(&"upgrades", &"vitality"), 1)
	offer.bonus_scale = hunter.upgrade_scale
	assert_eq(offer.scaled_modifiers()[0].flat, 15.0, "+10 HP card gives +15")


func test_mage_other_families_deal_less_damage() -> void:
	var holder := WeaponHolder.new()
	autofree(holder)
	holder.favored_family = &"energy"
	holder.off_family_scale = 0.75
	var staff: WeaponData = ContentDB.get_def(&"weapons", &"fire_staff")
	var sword: WeaponData = ContentDB.get_def(&"weapons", &"katana")
	assert_eq(holder.add_weapon(staff).stats.damage, WeaponStats.compute(staff, 1).damage)
	var slot := holder.add_weapon(sword)
	assert_almost_eq(slot.stats.damage, WeaponStats.compute(sword, 1).damage * 0.75, 0.001)
	slot.set_level(2)
	assert_almost_eq(slot.stats.damage, WeaponStats.compute(sword, 2).damage * 0.75, 0.001, "kept after a level up")
