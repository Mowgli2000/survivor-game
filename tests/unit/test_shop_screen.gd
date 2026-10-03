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


# --- Focus (keyboard/gamepad): a confirm press must never land on "Next wave" by accident ---

var _wallet: Wallet
var _weapons: WeaponHolder
var _shop: Shop
var _screen: ShopScreen


func _open_screen(money: int) -> void:
	var stats := StatBlock.from_defaults()
	_wallet = Wallet.new()
	_wallet.add(money)
	var inventory := Inventory.new(stats)
	_weapons = WeaponHolder.new()
	autofree(_weapons)
	var pulse: WeaponData = ContentDB.get_def(&"weapons", &"pulse")
	_weapons.add_weapon(pulse)
	_weapons.add_weapon(pulse)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var items: Array[ItemData] = []
	items.assign(ContentDB.get_all(&"items"))
	var weapon_pool: Array[WeaponData] = [pulse]
	_shop = Shop.new(ShopConfig.new(), _wallet, inventory, _weapons, weapon_pool, items, rng)
	_shop.open(1)
	for offer in _shop.offers:
		offer.weapon = null
		offer.item = ContentDB.get_def(&"items", &"magnet_glove")  # price 10
		offer.tier = 1
		offer.price = 10
	_screen = ShopScreen.new()
	add_child_autofree(_screen)
	_screen.setup(_shop, _wallet, inventory, _weapons, stats)
	_screen.open()
	_screen._accept_after = 0


func _focused() -> Control:
	return get_viewport().gui_get_focus_owner()


func test_focus_moves_to_another_card_after_buying() -> void:
	_open_screen(100)
	_screen._controls["buy:0"].grab_focus()
	_screen._controls["buy:0"].pressed.emit()
	assert_ne(_focused(), _screen._next, "one more confirm must not start the wave")
	assert_eq(_focused(), _screen._controls.get("buy:1"))


func test_initial_focus_is_a_card_when_the_first_one_is_too_expensive() -> void:
	_open_screen(0)
	assert_ne(_focused(), _screen._next)
	assert_eq(_focused(), _screen._controls.get("lock:0"))


func test_focus_stays_on_weapons_after_selling() -> void:
	_open_screen(100)
	_screen._controls["weapon:1"].pressed.emit()
	_screen._controls["sell"].grab_focus()
	_screen._controls["sell"].pressed.emit()
	assert_eq(_weapons.slot_count(), 1)
	assert_ne(_focused(), _screen._next)
	assert_eq(_focused(), _screen._controls.get("weapon:0"))


func _icon_tiles(node: Node) -> Array[IconTile]:
	var found: Array[IconTile] = []
	for child in node.get_children():
		if child is IconTile:
			found.append(child)
		found.append_array(_icon_tiles(child))
	return found


func test_every_offer_card_shows_its_icon() -> void:
	_open_screen(100)
	for card in _screen._cards.get_children():
		assert_eq(_icon_tiles(card).size(), 1, "one icon per card")


func test_owned_items_are_shown_as_icons_with_counts() -> void:
	_open_screen(100)
	_screen._controls["buy:0"].pressed.emit()
	_screen._controls["buy:1"].pressed.emit()
	var tiles := _icon_tiles(_screen._items_row)
	assert_eq(tiles.size(), 1, "two magnet gloves = one tile")
	assert_eq(tiles[0].badge.text, "×2")
