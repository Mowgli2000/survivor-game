extends GutTest
## Second look of a class (other sex): same character, another name, sprite and card.

const RUN := preload("res://src/run/run.tscn")


func after_each() -> void:
	get_tree().paused = false


func test_class_without_second_look_ignores_the_variant() -> void:
	var plain := CharacterData.new()
	plain.name_key = "CHARACTER_X"
	plain.sprite_id = &"x"
	plain.sprite_scale = 1.2
	assert_false(plain.has_alt_look())
	assert_eq(plain.sprite_id_for(1), &"x")
	assert_eq(plain.name_key_for(1), "CHARACTER_X")
	assert_eq(plain.sprite_scale_for(1), 1.2)
	assert_eq(plain.card_art_for(1), plain.card_art)


func test_gunslinger_has_a_second_look() -> void:
	var archer: CharacterData = ContentDB.get_def(&"characters", &"gunslinger")
	assert_true(archer.has_alt_look())
	assert_ne(archer.sprite_id_for(1), archer.sprite_id_for(0))
	assert_ne(archer.name_key_for(1), archer.name_key_for(0))
	assert_ne(archer.card_art_for(1), archer.card_art_for(0))
	assert_not_null(CharacterSelect.character_sheet(archer, 0))
	assert_not_null(CharacterSelect.character_sheet(archer, 1))


func test_every_second_look_has_its_sprite_and_card() -> void:
	for def in ContentDB.get_all(&"characters"):
		var character := def as CharacterData
		if not character.has_alt_look():
			continue
		assert_not_null(character.alt_card_art, "%s: card of the second look" % character.id)
		assert_not_null(CharacterSelect.character_sheet(character, 1), "%s: sprite of the second look" % character.id)
		assert_ne(character.alt_name_key, "", "%s: name of the second look" % character.id)


func test_run_uses_the_chosen_look() -> void:
	var setup := RunSetup.new()
	setup.character = ContentDB.get_def(&"characters", &"gunslinger")
	setup.variant = 1
	var run: Run = RUN.instantiate()
	run.seed_override = 2
	run.setup = setup
	add_child_autofree(run)
	assert_eq(run.players[0].variant, 1)
	assert_eq(run.player.animator.sheet, CharacterSelect.character_sheet(setup.character, 1))


func test_the_default_look_is_variant_zero() -> void:
	var setup := RunSetup.new()
	setup.character = ContentDB.get_def(&"characters", &"gunslinger")
	var run: Run = RUN.instantiate()
	run.seed_override = 2
	run.setup = setup
	add_child_autofree(run)
	assert_eq(run.players[0].variant, 0)
	assert_eq(run.player.animator.sheet, CharacterSelect.character_sheet(setup.character, 0))


func test_every_class_offers_both_looks() -> void:
	for def in ContentDB.get_all(&"characters"):
		assert_true((def as CharacterData).has_alt_look(), "%s has a second look" % (def as CharacterData).id)
