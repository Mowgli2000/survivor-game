class_name BalancePolicy
extends RefCounted
## How the balance simulator's player builds (ADR 0019): level-up card choice
## and shop turn, through the real Shop API (buy, merge, reroll). Kinds:
##   "dps"     offense first, survival when hurt;
##   "tank"    survival first;
##   "family"  one weapon family (the starting weapon's), offense items;
##   "economy" harvest and luck early (waves 1-8), then "dps";
##   "random"  any affordable offer, random cards (a weak, unfocused player);
##   "zone"    like "family", and Zone is worth 4 times more (area builds, D67).
## Scores are "points": a typical common item or card is worth about 1.

const KINDS: Array[String] = ["dps", "tank", "family", "economy", "random", "zone"]
## "zone" policy: Zone value multiplier.
const ZONE_FOCUS := 4.0
## Points per unit of flat value, per stat.
const FLAT: Dictionary[StringName, float] = {
	StatIds.MAX_HP: 0.2, StatIds.HP_REGEN: 1.0, StatIds.ARMOR: 1.0, StatIds.MOVE_SPEED: 0.04,
	StatIds.CRIT_CHANCE: 20.0, StatIds.CRIT_DAMAGE: 3.0, StatIds.PROJECTILE_COUNT: 4.0,
	StatIds.PIERCE: 2.0, StatIds.PICKUP_RANGE: 0.008, StatIds.DODGE: 33.0, StatIds.LIFESTEAL: 50.0,
	StatIds.LUCK: 0.1, StatIds.HARVEST: 0.15,
}
## Points per +100 % for multiplier stats.
const PERCENT: Dictionary[StringName, float] = {
	StatIds.DAMAGE: 20.0, StatIds.ATTACK_SPEED: 20.0, StatIds.RANGE: 6.0, StatIds.AREA: 10.0,
	StatIds.PROJECTILE_SPEED: 3.0, StatIds.KNOCKBACK: 2.0, StatIds.MAX_HP: 15.0, StatIds.MOVE_SPEED: 10.0,
}
const DEFENSE: Array[StringName] = [StatIds.MAX_HP, StatIds.HP_REGEN, StatIds.ARMOR, StatIds.DODGE,
	StatIds.LIFESTEAL, StatIds.MOVE_SPEED]
const ECONOMY: Array[StringName] = [StatIds.HARVEST, StatIds.LUCK]
## Weapon offer value: base + per tier, on top of the merge / family bonuses.
const WEAPON_BASE := 2.0
const WEAPON_PER_TIER := 2.5
const MAX_ACTIONS := 24
const MAX_REROLLS := 4

var kind: String = "dps"
## Set by the simulator after each wave: share of max HP lost (0..1+).
var last_wave_damage_ratio: float = 0.0
var _rng := RandomNumberGenerator.new()
## Family the "family" policy commits to (the starting weapon's).
var _focus: StringName = &""


func _init(p_kind: String = "dps", seed: int = 0) -> void:
	kind = p_kind if KINDS.has(p_kind) else "dps"
	_rng.seed = seed


func choose_upgrade(offers: Array[UpgradeOffer], _rp: RunPlayer) -> UpgradeOffer:
	if kind == "random":
		return offers[_rng.randi_range(0, offers.size() - 1)]
	var best := offers[0]
	var best_score := -INF
	for offer in offers:
		var score := score_modifiers(offer.scaled_modifiers(), 0)
		if score > best_score:
			best_score = score
			best = offer
	return best


## Buys, merges and rerolls until nothing worth it is left (or the action cap).
func shop_turn(rp: RunPlayer, wave: int) -> void:
	play_shop(rp.shop, rp.wallet, rp.player.weapons, wave)


## Same, from the parts (the fast wave simulator has no Player).
func play_shop(shop: Shop, wallet: Wallet, weapons: WeaponHolder, wave: int) -> void:
	if _focus == &"" and weapons.slot_count() > 0 and not weapons.get_slots()[0].data.families.is_empty():
		_focus = weapons.get_slots()[0].data.families[0]
	var rerolls := 0
	for action in MAX_ACTIONS:
		_merge_all(shop, weapons)
		var pick := _best_offer(shop, weapons, wave)
		if pick >= 0:
			shop.buy(pick)
			continue
		var reserve := 0 if wave >= 19 else shop.reroll_cost() * 2
		if kind != "random" and rerolls < MAX_REROLLS and wallet.amount >= shop.reroll_cost() + reserve:
			if shop.reroll():
				rerolls += 1
				continue
		break
	_merge_all(shop, weapons)


## Points of a list of modifiers for this policy at `wave`.
func score_modifiers(modifiers: Array[StatModifier], wave: int) -> float:
	var hurt := clampf(last_wave_damage_ratio, 0.0, 1.5)
	var score := 0.0
	for m in modifiers:
		var value: float = FLAT.get(m.stat, 0.0) * m.flat + PERCENT.get(m.stat, 0.0) * m.percent
		if DEFENSE.has(m.stat):
			value *= (2.5 if kind == "tank" else 1.0) + hurt * 2.0
		elif ECONOMY.has(m.stat):
			value *= 6.0 if kind == "economy" and wave <= 8 else 1.0
		elif kind == "tank":
			value *= 0.6
		if kind == "zone" and m.stat == StatIds.AREA:
			value *= ZONE_FOCUS
		score += value
	return score


func _best_offer(shop: Shop, weapons: WeaponHolder, wave: int) -> int:
	var candidates: Array[int] = []
	var best := -1
	var best_value := 0.0
	for i in shop.offers.size():
		if not shop.can_buy(i):
			continue
		var offer := shop.offers[i]
		candidates.append(i)
		var points := _weapon_points(offer, weapons) if offer.is_weapon() else _item_points(offer.item, wave)
		# Value for money; worth buying only above a small threshold.
		var value := points / maxf(offer.price, 1.0) * 10.0
		if points > 0.6 and value > best_value:
			best_value = value
			best = i
	if kind == "random":
		return candidates[_rng.randi_range(0, candidates.size() - 1)] if not candidates.is_empty() else -1
	return best


func _weapon_points(offer: ShopOffer, weapons: WeaponHolder) -> float:
	var data := offer.weapon
	var points := WEAPON_BASE + WEAPON_PER_TIER * offer.tier
	var same := 0
	var family := 0
	for slot in weapons.get_slots():
		if slot.data == data:
			same += 1
		for f in data.families:
			if slot.data.families.has(f):
				family += 1
				break
	if weapons.is_full():
		# Full: only a copy that merges into an owned weapon is useful.
		return points * 1.5 if weapons.find_slot(data, offer.tier) >= 0 else 0.0
	points += same * 2.0 + family * 1.0
	if kind in ["family", "zone"] and _focus != &"" and not data.families.has(_focus):
		return 0.0
	if kind == "tank":
		points *= 0.7
	return points


func _item_points(item: ItemData, wave: int) -> float:
	var points := score_modifiers(item.modifiers, wave)
	# Special effects: a fixed bonus (the simulator does not model each one).
	if not item.effects.is_empty():
		points += 2.0 * item.effects.size()
	return points


static func _merge_all(shop: Shop, weapons: WeaponHolder) -> void:
	var merged := true
	while merged:
		merged = false
		for i in weapons.slot_count():
			if shop.can_merge(i) and shop.merge_weapon(i):
				merged = true
				break
