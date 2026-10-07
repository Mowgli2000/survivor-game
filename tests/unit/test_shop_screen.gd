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
	assert_eq(texts[1], "Whetstone")
	assert_eq(texts[2], "+8% Damage\n-3% Attack speed")


func test_weapon_card_text() -> void:
	var offer := ShopOffer.new()
	offer.weapon = ContentDB.get_def(&"weapons", &"katana")
	offer.tier = 3
	var texts := ShopScreen.describe(offer)
	assert_eq(texts[0], "Weapon · III · Blades")
	assert_eq(texts[1], "Flame sword")



func test_item_tooltip_shows_the_total_of_owned_copies() -> void:
	var item: ItemData = ContentDB.get_def(&"items", &"sharpened_edge")
	assert_eq(ShopScreen.item_tooltip(item, 1), "Whetstone\n+8% Damage\n-3% Attack speed")
	assert_eq(ShopScreen.item_tooltip(item, 3),
		"Whetstone\n+8% Damage\n-3% Attack speed\n\nTotal with ×3:\n+24% Damage\n-9% Attack speed")


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


## Sold cards have no buttons: left/right must jump over them (gamepad bug:
## stuck on the first card when the two middle ones were sold).
func test_left_right_skip_sold_cards() -> void:
	_open_screen(100)
	_screen._controls["buy:1"].pressed.emit()
	_screen._controls["buy:2"].pressed.emit()
	var first: Button = _screen._controls["buy:0"]
	var last: Button = _screen._controls["buy:3"]
	assert_eq(first.get_node_or_null(first.focus_neighbor_right), last)
	assert_eq(last.get_node_or_null(last.focus_neighbor_left), first)
	var lock_first: Button = _screen._controls["lock:0"]
	assert_eq(lock_first.get_node_or_null(lock_first.focus_neighbor_right), _screen._controls["lock:3"])


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


func test_cards_and_buttons_use_the_theme() -> void:
	_open_screen(100)
	var card := _screen._cards.get_child(0) as PanelContainer
	var style := card.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(style.border_color, UiTheme.OUTLINE, "black outline")
	assert_eq(Color(style.shadow_color, 1.0), Tiers.color(1), "tier glow")
	assert_eq(_screen._next.theme_type_variation, &"CtaButton")
	assert_eq(_screen._title.theme_type_variation, &"TitleLabel")


func test_effect_item_card_shows_its_effect_and_uniqueness() -> void:
	var offer := ShopOffer.new()
	offer.item = ContentDB.get_def(&"items", &"chain_reactor")
	offer.tier = 3
	var texts := ShopScreen.describe(offer)
	assert_eq(texts[2], "20% chance: killed enemies explode\n(Unique)")


func test_names_use_the_rarity_color() -> void:
	var offer := ShopOffer.new()
	offer.weapon = ContentDB.get_def(&"weapons", &"katana")
	offer.tier = 3
	assert_eq(ShopScreen.name_color(offer), Tiers.color(3), "not the katana's neon pink")
	var item := ShopOffer.new()
	item.item = ContentDB.get_def(&"items", &"sharpened_edge")
	item.tier = 2
	assert_eq(ShopScreen.name_color(item), Tiers.color(2))


func test_limited_item_card_shows_owned_copies() -> void:
	var offer := ShopOffer.new()
	offer.item = ContentDB.get_def(&"items", &"scrap_magnet")
	offer.tier = 1
	assert_true(ShopScreen.describe(offer, 1)[2].ends_with("Owned: 1/3"))


func test_capped_bonus_is_marked_max() -> void:
	var stats := StatBlock.from_defaults()
	var cap := StatModifier.new()
	cap.stat = StatIds.PROJECTILE_COUNT
	cap.flat = 5.0
	stats.add_modifier(cap)
	var shot := StatModifier.new()
	shot.stat = StatIds.PROJECTILE_COUNT
	shot.flat = 1.0
	assert_string_contains(LevelUpScreen.describe_modifiers([shot], stats), "(max)")
	assert_false(LevelUpScreen.describe_modifiers([shot]).contains("(max)"))


func test_next_wave_is_pinned_at_the_bottom_and_the_list_never_grows_past_two_rows() -> void:
	# Regression (playtests): in the shop column the button went down as weapons and
	# items were added, until it left the screen. Pinned at the bottom, solo and coop.
	for compact in [false, true]:
		var screen := ShopScreen.new(compact)
		add_child_autofree(screen)
		var root := screen.get_child(0) as Control
		assert_eq(screen._next.get_parent(), root, "outside the growing column")
		assert_eq(screen._next.anchor_bottom, 1.0, "anchored to the bottom")
		assert_ne(screen._reroll.get_parent(), root, "away from Reroll")
	var two_rows := 2 * ShopScreen.ITEM_ICON_SMALL + ShopScreen.ITEM_GAP
	assert_almost_eq(ShopScreen.items_height(59), two_rows, 0.01, "every item owned: still two rows")
	assert_almost_eq(ShopScreen.items_height(3), ShopScreen.ITEM_ICON, 0.01, "few items: one row")


func test_owned_weapon_details_show_description_and_tier_stats() -> void:
	var data: WeaponData = ContentDB.get_def(&"weapons", &"bomb")
	var low := ShopScreen.weapon_details(WeaponSlot.new(data, 1))
	var high := ShopScreen.weapon_details(WeaponSlot.new(data, 4))
	assert_string_contains(low, "Bomb")
	assert_string_contains(low, String(TranslationServer.translate(data.description_key)))
	assert_string_contains(low, "Damage")
	assert_string_contains(low, "Blast")
	assert_ne(low, high, "the numbers follow the tier")




func test_merge_shortcut_merges_the_focused_weapon() -> void:
	_open_screen(100)
	assert_eq(_weapons.slot_count(), 2, "two pulses of the same tier")
	_screen._controls["weapon:0"].grab_focus()
	var event := InputEventAction.new()
	event.action = &"merge_weapon"
	event.pressed = true
	_screen._unhandled_input(event)
	assert_eq(_weapons.slot_count(), 1, "merged into one weapon")


func test_lock_sits_under_buy_in_coop() -> void:
	_open_screen(100)
	var stats := StatBlock.from_defaults()
	var screen := ShopScreen.new(true)
	add_child_autofree(screen)
	screen.setup(_shop, _wallet, Inventory.new(stats), _weapons, stats)
	screen.open()
	var buy: Control = screen._controls["buy:0"]
	var lock: Control = screen._controls["lock:0"]
	assert_eq(buy.get_parent(), lock.get_parent(), "same column")
	assert_gt(lock.get_index(), buy.get_index(), "lock under buy")


func test_coop_shop_shows_stats_while_share_is_held() -> void:
	_open_screen(100)
	var stats := StatBlock.from_defaults()
	var screen := ShopScreen.new(true)
	add_child_autofree(screen)
	screen.setup(_shop, _wallet, Inventory.new(stats), _weapons, stats)
	screen.open()
	assert_false(screen.stats_panel.visible)
	var event := InputEventAction.new()
	event.action = &"show_stats"
	event.pressed = true
	screen._input(event)
	assert_true(screen.stats_panel.visible)
	event.pressed = false
	screen._input(event)
	assert_false(screen.stats_panel.visible)


func test_reroll_shortcut_rerolls_the_offers() -> void:
	_open_screen(100)
	var before := _wallet.amount
	var event := InputEventAction.new()
	event.action = &"reroll"
	event.pressed = true
	_screen._unhandled_input(event)
	assert_lt(_wallet.amount, before, "the reroll was paid")


func test_owned_weapon_keeps_its_card_shape_on_hover() -> void:
	_open_screen(100)
	var button: Button = _screen._controls["weapon:0"]
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	for state in ["hover", "pressed"]:
		var style := button.get_theme_stylebox(state) as StyleBoxFlat
		assert_eq(style.corner_radius_top_left, normal.corner_radius_top_left, "%s: same corners" % state)
