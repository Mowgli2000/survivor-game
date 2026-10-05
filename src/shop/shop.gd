class_name Shop
extends RefCounted
## Brotato-style shop between waves: random slots (weapons or items), paid
## rerolls, locks kept to the next shop, buying, selling and merging weapons.
## Pure logic: ShopScreen only reads it and calls its methods.

signal changed

## Player stats read for the luck stat (null: no luck). Set by Run.
var luck_stats: StatBlock
var offers: Array[ShopOffer] = []
var wave: int = 1
## Rerolls done in the current shop (the cost grows with each one).
var rerolls: int = 0

var _config: ShopConfig
var _wallet: Wallet
var _inventory: Inventory
var _weapons: WeaponHolder
## Character class rules (CharacterData): price and reroll cost multipliers.
var price_multiplier: float = 1.0
var reroll_multiplier: float = 1.0
var _weapon_pool: Array[WeaponData] = []
var _item_pool: Array[ItemData] = []
var _rng: RandomNumberGenerator


func _init(config: ShopConfig, wallet: Wallet, inventory: Inventory, weapons: WeaponHolder,
		weapon_pool: Array[WeaponData], item_pool: Array[ItemData], rng: RandomNumberGenerator) -> void:
	_config = config
	_wallet = wallet
	_inventory = inventory
	_weapons = weapons
	_weapon_pool = weapon_pool
	_item_pool = item_pool
	_rng = rng


## New shop for `p_wave`: locked slots are kept (re-priced), the others re-rolled.
func open(p_wave: int) -> void:
	wave = p_wave
	rerolls = 0
	_fill()
	changed.emit()


func reroll_cost() -> int:
	return scaled_reroll_cost(_config.reroll_cost(wave, rerolls))


## A reroll cost after the class multiplier (never free).
func scaled_reroll_cost(cost: int) -> int:
	return maxi(1, roundi(cost * reroll_multiplier))


func reroll() -> bool:
	if not _wallet.spend(reroll_cost()):
		return false
	rerolls += 1
	_fill()
	changed.emit()
	return true


func toggle_lock(index: int) -> void:
	if not _valid(index) or offers[index].sold:
		return
	offers[index].locked = not offers[index].locked
	changed.emit()


func can_buy(index: int) -> bool:
	if not _valid(index):
		return false
	var offer := offers[index]
	if offer.sold or not _wallet.can_afford(offer.price):
		return false
	if offer.is_weapon():
		return not _weapons.is_full() or _weapons.find_slot(offer.weapon, offer.tier) >= 0
	return _inventory.can_add(offer.item)


func buy(index: int) -> bool:
	if not can_buy(index):
		return false
	var offer := offers[index]
	_wallet.spend(offer.price)
	if offer.is_weapon():
		if _weapons.is_full():
			# Brotato rule: buying a copy while full merges it into the owned one.
			_weapons.upgrade_slot(_weapons.find_slot(offer.weapon, offer.tier))
		else:
			_weapons.add_weapon(offer.weapon, offer.tier)
	else:
		_inventory.add(offer.item)
	offer.sold = true
	offer.locked = false
	changed.emit()
	return true


func sell_price(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= _weapons.slot_count():
		return 0
	var slot := _weapons.get_slots()[slot_index]
	return _config.sell_price(slot.data, slot.level, wave)


## The last weapon can never be sold.
func can_sell(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < _weapons.slot_count() and _weapons.slot_count() > 1


func sell_weapon(slot_index: int) -> int:
	if not can_sell(slot_index):
		return 0
	var gain := sell_price(slot_index)
	_weapons.remove_weapon(slot_index)
	_wallet.add(gain)
	changed.emit()
	return gain


func can_merge(slot_index: int) -> bool:
	return _weapons.find_merge_partner(slot_index) >= 0


func merge_weapon(slot_index: int) -> bool:
	if not _weapons.merge(slot_index):
		return false
	changed.emit()
	return true


func _valid(index: int) -> bool:
	return index >= 0 and index < offers.size()


## Keeps locked unsold slots (new price), rolls every other slot.
func _fill() -> void:
	var taken: Array[Resource] = []
	for offer in offers:
		if offer.locked and not offer.sold:
			taken.append(offer.weapon if offer.is_weapon() else offer.item)
	offers.resize(_config.slot_count)
	for i in _config.slot_count:
		var offer := offers[i]
		if offer != null and offer.locked and not offer.sold:
			offer.price = _price(offer)
			continue
		offers[i] = _roll(taken)


func _roll(taken: Array[Resource]) -> ShopOffer:
	var offer := ShopOffer.new()
	offer.tier = _config.roll_tier(wave, _rng, luck_stats.get_value(StatIds.LUCK) if luck_stats != null else 0.0)
	if _weapon_pool.is_empty() or _rng.randf() >= _config.weapon_chance:
		offer.item = _pick_item(offer.tier, taken)
	if offer.item != null:
		offer.tier = offer.item.tier
		taken.append(offer.item)
	elif not _weapon_pool.is_empty():
		offer.weapon = _pick_weapon(taken)
		taken.append(offer.weapon)
	else:
		offer.sold = true  # nothing left to sell
		return offer
	offer.price = _price(offer)
	return offer


## An item of `tier` not yet in the stock and not capped; lower tiers as fallback.
func _pick_item(tier: int, taken: Array[Resource]) -> ItemData:
	for t in range(tier, 0, -1):
		var candidates: Array[ItemData] = []
		for item in _item_pool:
			if item.tier == t and _inventory.can_add(item) and not taken.has(item) 					and not _is_useless(item):
				candidates.append(item)
		if not candidates.is_empty():
			return candidates[_rng.randi_range(0, candidates.size() - 1)]
	return null


## A plain stat item whose every bonus is capped (projectiles at +5...).
func _is_useless(item: ItemData) -> bool:
	return item.effects.is_empty() and luck_stats != null and luck_stats.all_wasted(item.modifiers)


func _pick_weapon(taken: Array[Resource]) -> WeaponData:
	var candidates: Array[WeaponData] = []
	for weapon in _weapon_pool:
		if not taken.has(weapon):
			candidates.append(weapon)
	if candidates.is_empty():
		candidates = _weapon_pool
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _price(offer: ShopOffer) -> int:
	var base := _config.weapon_price(offer.weapon, offer.tier, wave) if offer.is_weapon() \
		else _config.item_price(offer.item, wave)
	return maxi(1, roundi(base * price_multiplier))
