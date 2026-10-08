extends GutTest
## Skins: owned skins extend a class's looks, and the skin shop buys them (ADR 0023).

var _skin: SkinData
var _pricey: SkinData


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()
	_skin = _make(&"ronin_ember", 150, &"ronin_pc_m")
	_pricey = _make(&"ronin_gold", 400, &"ronin_pc")
	ContentDB._defs[&"skins"] = {_skin.id: _skin, _pricey.id: _pricey}


func after_each() -> void:
	ContentDB.reload()
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()


func _make(id: StringName, price: int, sprite: StringName) -> SkinData:
	var skin := SkinData.new()
	skin.id = id
	skin.name_key = "SKIN_%s" % id
	skin.character_id = &"ronin"
	skin.price = price
	skin.sprite_id = sprite
	skin.sprite_scale = 1.1
	return skin


func test_a_class_has_only_its_own_looks_until_a_skin_is_bought() -> void:
	var ronin: CharacterData = ContentDB.get_def(&"characters", &"ronin")
	var base := ronin.base_look_count()
	assert_eq(ronin.look_count(), base)
	assert_null(ronin.skin_for(base))
	SaveService.profile.unlock(&"skins", _pricey.id)
	SaveService.profile.unlock(&"skins", _skin.id)
	assert_eq(ronin.look_count(), base + 2)
	assert_eq(ronin.skin_for(base), _skin, "cheapest skin first")
	assert_eq(ronin.skin_for(base + 1), _pricey)
	assert_eq(ronin.sprite_id_for(base), &"ronin_pc_m")
	assert_eq(ronin.name_key_for(base + 1), "SKIN_ronin_gold")
	assert_almost_eq(ronin.sprite_scale_for(base), 1.1, 0.001)


func test_own_looks_are_untouched_by_skins() -> void:
	SaveService.profile.unlock(&"skins", _skin.id)
	var ronin: CharacterData = ContentDB.get_def(&"characters", &"ronin")
	assert_eq(ronin.sprite_id_for(0), ronin.sprite_id)
	assert_eq(ronin.name_key_for(0), ronin.name_key)
	var other: CharacterData = ContentDB.get_def(&"characters", &"mage")
	assert_eq(other.look_count(), other.base_look_count(), "a skin belongs to its class only")


func test_the_turntable_counts_bought_skins() -> void:
	var ronin: CharacterData = ContentDB.get_def(&"characters", &"ronin")
	var before := CharacterSelect.look_count(ronin)
	SaveService.profile.unlock(&"skins", _skin.id)
	assert_eq(CharacterSelect.look_count(ronin), before + 1)


func test_shop_lists_a_class_s_skins_and_buys_them() -> void:
	SaveService.profile.add_shards(200)
	var screen := SkinShopScreen.new()
	add_child_autofree(screen)
	screen.open()
	screen._show_class(&"ronin")
	assert_eq(screen.card_count(), 2)
	var buttons := screen.buy_buttons()
	assert_false(buttons[0].disabled)
	buttons[1].pressed.emit()
	assert_eq(SaveService.profile.shards, 200, "400 shards needed: refused")
	buttons[0].pressed.emit()
	assert_eq(SaveService.profile.shards, 50)
	assert_true(SaveService.profile.is_unlocked(&"skins", _skin.id))
	assert_true(screen.buy_buttons()[0].disabled, "owned: nothing more to buy")


func test_shop_shows_the_balance_and_an_empty_class() -> void:
	SaveService.profile.add_shards(75)
	var screen := SkinShopScreen.new()
	add_child_autofree(screen)
	screen.open()
	assert_string_contains(screen._shards.text, "75")
	screen._show_class(&"mage")
	assert_eq(screen.card_count(), 0)
	assert_true(screen._empty.visible)
