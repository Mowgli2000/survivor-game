extends GutTest
## Shop: tier odds, prices, rerolls, locks, buying, selling and merging.

var _config: ShopConfig
var _wallet: Wallet
var _stats: StatBlock
var _inventory: Inventory
var _weapons: WeaponHolder
var _rng: RandomNumberGenerator
var _weapon_a: WeaponData
var _item_cheap: ItemData


func _weapon_data(id: StringName, price: int) -> WeaponData:
	var data := WeaponData.new()
	data.id = id
	data.base_price = price
	for i in Tiers.COUNT - 1:
		data.levels.append(WeaponLevel.new())
	return data


func _item(id: StringName, tier: int, price: int, max_count: int = 0) -> ItemData:
	var mod := StatModifier.new()
	mod.stat = StatIds.ARMOR
	mod.flat = 1.0
	var item := ItemData.new()
	item.id = id
	item.tier = tier
	item.base_price = price
	item.max_count = max_count
	item.modifiers = [mod]
	return item


func before_each() -> void:
	_config = ShopConfig.new()
	_wallet = Wallet.new()
	_stats = StatBlock.from_defaults()
	_inventory = Inventory.new(_stats)
	_weapons = WeaponHolder.new()
	_weapons.max_slots = 2
	autofree(_weapons)
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42
	_weapon_a = _weapon_data(&"a", 10)
	_item_cheap = _item(&"cheap", 1, 5)


func _shop(weapons: Array[WeaponData], items: Array[ItemData]) -> Shop:
	return Shop.new(_config, _wallet, _inventory, _weapons, weapons, items, _rng)


## Forces slot `index` to sell `weapon` or `item` at `tier` (deterministic tests).
func _force(shop: Shop, index: int, weapon: WeaponData, item: ItemData, tier: int = 1) -> void:
	var offer := shop.offers[index]
	offer.weapon = weapon
	offer.item = item
	offer.tier = tier
	offer.sold = false
	offer.locked = false
	offer.price = _config.weapon_price(weapon, tier, shop.wave) if weapon != null else _config.item_price(item, shop.wave)


# --- ShopConfig -------------------------------------------------------------

func test_tiers_never_appear_before_their_wave() -> void:
	for i in 2000:
		assert_eq(_config.roll_tier(1, _rng), 1)
	var best := 1
	for i in 2000:
		best = maxi(best, _config.roll_tier(3, _rng))
	assert_eq(best, 2, "wave 3: tier II possible, III not yet")


func test_tier_chance_grows_and_is_capped() -> void:
	assert_almost_eq(_config.tier_chance(2, 2), 0.10, 0.001)
	assert_almost_eq(_config.tier_chance(2, 4), 0.20, 0.001)
	assert_almost_eq(_config.tier_chance(2, 50), 0.60, 0.001)
	assert_eq(_config.tier_chance(4, 7), 0.0)
	assert_eq(_config.tier_chance(1, 10), 0.0, "tier I is the fallback, never rolled")


func test_prices_and_reroll_cost() -> void:
	assert_eq(_config.scaled_price(10.0, 1), 10)
	assert_eq(_config.scaled_price(10.0, 11), 20, "+10 % per wave")
	assert_eq(_config.weapon_price(_weapon_a, 2, 1), 19, "tier II = x1.9")
	assert_eq(_config.reroll_cost(1, 0), 1)
	assert_eq(_config.reroll_cost(1, 2), 3)
	assert_eq(_config.reroll_cost(10, 0), 6)
	assert_eq(_config.reroll_cost(10, 1), 11)



func test_reroll_cost_factors_are_tunable() -> void:
	var config := ShopConfig.new()
	config.reroll_wave_factor = 0.75
	config.reroll_step_factor = 0.6
	assert_eq(config.reroll_cost(10, 0), 8, "1 + floor(10 x 0.75)")
	assert_eq(config.reroll_cost(10, 2), 20, "+ floor(10 x 0.6) per reroll")
	assert_eq(config.reroll_cost(1, 1), 2, "step never below 1")


func test_rerolls_after_the_cheap_ones_get_steep() -> void:
	var config := ShopConfig.new()
	config.reroll_wave_factor = 0.75
	config.reroll_step_factor = 0.6
	config.reroll_cheap_count = 2
	config.reroll_steep_factor = 2.5
	# Wave 14: base 11, step 8.
	assert_eq(config.reroll_cost(14, 0), 11)
	assert_eq(config.reroll_cost(14, 1), 19, "second reroll still linear")
	assert_eq(config.reroll_cost(14, 2), 48, "third: x2.5")
	assert_eq(config.reroll_cost(14, 3), 119)
	assert_eq(config.reroll_cost(14, 4), 297)


func test_second_reroll_costs_at_least_half_more() -> void:
	var config := ShopConfig.new()
	config.reroll_wave_factor = 0.75
	config.reroll_step_factor = 0.6
	config.reroll_cheap_count = 2
	config.reroll_cheap_min_growth = 1.5
	assert_eq(config.reroll_cost(3, 0), 3)
	assert_eq(config.reroll_cost(3, 1), 5, "x1.5 beats the linear +1")
	assert_eq(config.reroll_cost(14, 1), 19, "the linear step is already above x1.5")


func test_default_shop_makes_five_rerolls_cost_more_than_a_late_wave_of_income() -> void:
	var config: ShopConfig = load("res://data/shop/default.tres")
	var total := 0
	for i in 5:
		total += config.reroll_cost(14, i)
	assert_gt(total, 400)


# --- Shop -------------------------------------------------------------------

func test_open_fills_every_slot() -> void:
	var shop := _shop([_weapon_a], [_item_cheap, _item(&"b", 1, 5)])
	shop.open(1)
	assert_eq(shop.offers.size(), _config.slot_count)
	for offer in shop.offers:
		assert_true(offer.weapon != null or offer.item != null)
		assert_false(offer.sold)
		assert_gt(offer.price, 0)


func test_buy_item_spends_and_applies() -> void:
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	_force(shop, 0, null, _item_cheap)
	_wallet.add(5)
	assert_true(shop.buy(0))
	assert_eq(_wallet.amount, 0)
	assert_eq(_inventory.count(_item_cheap), 1)
	assert_true(shop.offers[0].sold)


func test_cannot_buy_twice() -> void:
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	_force(shop, 0, null, _item_cheap)
	_wallet.add(100)
	assert_true(shop.buy(0))
	assert_false(shop.buy(0), "sold slot")
	assert_eq(_inventory.count(_item_cheap), 1)
	assert_eq(_wallet.amount, 95)


func test_buy_refused_without_money() -> void:
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	_force(shop, 0, null, _item_cheap)
	_wallet.add(4)
	assert_false(shop.can_buy(0))
	assert_false(shop.buy(0))
	assert_eq(_wallet.amount, 4)


func test_buy_weapon_adds_a_slot() -> void:
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	_force(shop, 0, _weapon_a, null, 2)
	_wallet.add(100)
	assert_true(shop.buy(0))
	assert_eq(_weapons.slot_count(), 1)
	assert_eq(_weapons.get_slots()[0].level, 2, "bought at the offer's tier")


func test_buy_weapon_when_full_merges() -> void:
	var other := _weapon_data(&"other", 10)
	_weapons.add_weapon(_weapon_a, 1)
	_weapons.add_weapon(other, 1)
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	_force(shop, 0, _weapon_a, null, 1)
	_wallet.add(100)
	assert_true(shop.can_buy(0))
	assert_true(shop.buy(0))
	assert_eq(_weapons.slot_count(), 2, "no new slot")
	assert_eq(_weapons.get_slots()[0].level, 2, "merged into the owned copy")


func test_buy_weapon_refused_when_full_without_match() -> void:
	var other := _weapon_data(&"other", 10)
	_weapons.add_weapon(other, 1)
	_weapons.add_weapon(other, 2)
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	_force(shop, 0, _weapon_a, null, 1)
	_wallet.add(100)
	assert_false(shop.can_buy(0))
	assert_false(shop.buy(0))
	assert_eq(_wallet.amount, 100)


func test_max_count_item_is_not_buyable() -> void:
	var unique := _item(&"unique", 1, 5, 1)
	var shop := _shop([_weapon_a], [unique])
	shop.open(1)
	_force(shop, 0, null, unique)
	_force(shop, 1, null, unique)
	_wallet.add(100)
	assert_true(shop.buy(0))
	assert_false(shop.can_buy(1))


func test_reroll_costs_more_each_time_and_keeps_locks() -> void:
	var shop := _shop([_weapon_a], [_item_cheap, _item(&"b", 1, 5), _item(&"c", 1, 5)])
	shop.open(1)
	_wallet.add(100)
	shop.toggle_lock(2)
	var locked := shop.offers[2]
	assert_eq(shop.reroll_cost(), 1)
	assert_true(shop.reroll())
	assert_eq(shop.reroll_cost(), 2)
	assert_true(shop.reroll())
	assert_eq(_wallet.amount, 97)
	assert_same(shop.offers[2], locked, "locked slot kept")
	assert_true(locked.locked)


func test_reroll_without_money_changes_nothing() -> void:
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	var before := shop.offers.duplicate()
	assert_false(shop.reroll())
	assert_eq(_wallet.amount, 0)
	for i in before.size():
		assert_same(shop.offers[i], before[i])


func test_lock_survives_next_shop_with_new_price() -> void:
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	_force(shop, 0, null, _item_cheap)
	shop.toggle_lock(0)
	var locked := shop.offers[0]
	shop.open(11)
	assert_same(shop.offers[0], locked)
	assert_eq(locked.price, 10, "re-priced for wave 11")
	assert_eq(shop.rerolls, 0)
	shop.toggle_lock(0)
	assert_false(locked.locked)


func test_locked_item_at_max_count_is_not_buyable() -> void:
	var unique := _item(&"unique", 1, 5, 1)
	var shop := _shop([_weapon_a], [unique])
	shop.open(1)
	_force(shop, 0, null, unique)
	shop.toggle_lock(0)
	_inventory.add(unique)
	shop.open(2)
	_wallet.add(100)
	assert_false(shop.can_buy(0))


func test_sell_weapon() -> void:
	_weapons.add_weapon(_weapon_a, 1)
	_weapons.add_weapon(_weapon_a, 2)
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	assert_eq(shop.sell_price(1), 5, "25 % of 19, rounded")
	assert_eq(shop.sell_weapon(1), 5)
	assert_eq(_wallet.amount, 5)
	assert_eq(_weapons.slot_count(), 1)


func test_last_weapon_cannot_be_sold() -> void:
	_weapons.add_weapon(_weapon_a, 1)
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	assert_false(shop.can_sell(0))
	assert_eq(shop.sell_weapon(0), 0)
	assert_eq(_weapons.slot_count(), 1)


func test_merge_through_shop() -> void:
	_weapons.add_weapon(_weapon_a, 1)
	_weapons.add_weapon(_weapon_a, 1)
	var shop := _shop([_weapon_a], [_item_cheap])
	shop.open(1)
	assert_true(shop.can_merge(0))
	assert_true(shop.merge_weapon(0))
	assert_eq(_weapons.slot_count(), 1)
	assert_eq(_weapons.get_slots()[0].level, 2)


func test_same_seed_same_stock() -> void:
	var items: Array[ItemData] = [_item_cheap, _item(&"b", 1, 5), _item(&"c", 2, 9)]
	var weapons: Array[WeaponData] = [_weapon_a, _weapon_data(&"z", 12)]
	_rng.seed = 7
	var first := _shop(weapons, items)
	first.open(6)
	var ids: Array = []
	for offer in first.offers:
		ids.append([offer.weapon, offer.item, offer.tier])
	_rng.seed = 7
	var second := _shop(weapons, items)
	second.open(6)
	for i in second.offers.size():
		assert_eq([second.offers[i].weapon, second.offers[i].item, second.offers[i].tier], ids[i])


# --- Class rules (CharacterData) ---------------------------------------------

func test_class_price_multiplier_lowers_prices() -> void:
	var shop := _shop([], [_item_cheap])
	shop.price_multiplier = 0.8
	shop.open(1)
	var base := _config.item_price(_item_cheap, 1)
	var checked := 0
	for offer in shop.offers:
		if offer.item == _item_cheap:
			assert_eq(offer.price, maxi(1, roundi(base * 0.8)))
			checked += 1
	assert_gt(checked, 0)


func test_class_reroll_multiplier_raises_reroll_cost() -> void:
	var shop := _shop([], [_item_cheap])
	shop.open(10)
	var normal := shop.reroll_cost()
	shop.reroll_multiplier = 1.5
	assert_eq(shop.reroll_cost(), roundi(normal * 1.5))


func test_items_whose_bonuses_are_all_capped_are_not_sold() -> void:
	var shot := StatModifier.new()
	shot.stat = StatIds.PROJECTILE_COUNT
	shot.flat = 1.0
	var useless := _item(&"shot", 1, 5)
	useless.modifiers = [shot]
	_stats.add_modifier(_mod_flat(StatIds.PROJECTILE_COUNT, 5.0))
	var shop := _shop([], [useless, _item_cheap])
	shop.luck_stats = _stats
	shop.open(1)
	for offer in shop.offers:
		assert_ne(offer.item, useless, "projectiles at +5: not offered")


func _mod_flat(stat: StringName, flat: float) -> StatModifier:
	var mod := StatModifier.new()
	mod.stat = stat
	mod.flat = flat
	return mod
