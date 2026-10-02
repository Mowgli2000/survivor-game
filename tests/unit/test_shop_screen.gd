extends GutTest
## Shop card texts (independent of the layout).


func before_each() -> void:
	TranslationServer.set_locale("en")


func test_item_card_text() -> void:
	var offer := ShopOffer.new()
	offer.item = ContentDB.get_def(&"items", &"sharpened_edge")
	offer.tier = 1
	var texts := ShopScreen.describe(offer)
	assert_eq(texts[0], "Item · I")
	assert_eq(texts[1], "Sharpened edge")
	assert_eq(texts[2], "+8% Damage\n-3% Attack speed")


func test_weapon_card_text() -> void:
	var offer := ShopOffer.new()
	offer.weapon = ContentDB.get_def(&"weapons", &"katana")
	offer.tier = 3
	var texts := ShopScreen.describe(offer)
	assert_eq(texts[0], "Weapon · III")
	assert_eq(texts[1], "Plasma katana")
