class_name Progression
extends RefCounted
## XP and levels of the current run. Level-ups are queued in `pending_level_ups`
## and consumed one by one when the player picks an upgrade.

signal xp_changed(xp: int, xp_needed: int)
signal leveled_up(level: int)

var level: int = 1
var xp: int = 0
var pending_level_ups: int = 0

var _xp_base: float
var _xp_exponent: float


func _init(xp_base: float, xp_exponent: float) -> void:
	_xp_base = xp_base
	_xp_exponent = xp_exponent


func xp_needed(for_level: int = level) -> int:
	return maxi(1, roundi(_xp_base * pow(for_level, _xp_exponent)))


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		pending_level_ups += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed())


## Draws `count` distinct stat upgrades (weight = UpgradeData.weight), each with
## a tier rolled by `shop_config` for `wave` (tier I without config).
func roll_offers(stat_pool: Array[UpgradeData], count: int, rng: RandomNumberGenerator,
		shop_config: ShopConfig = null, wave: int = 1, luck: float = 0.0) -> Array[UpgradeOffer]:
	var weights := PackedFloat32Array()
	for upgrade in stat_pool:
		weights.append(upgrade.weight)
	var result: Array[UpgradeOffer] = []
	for index in WeightedPicker.pick_distinct(weights, count, rng):
		var tier := shop_config.roll_tier(wave, rng, luck) if shop_config != null else 1
		result.append(UpgradeOffer.for_stat(stat_pool[index], tier))
	return result


## Applies a level-up card (tier-scaled) and consumes one pending level-up.
func apply_offer(offer: UpgradeOffer, stats: StatBlock) -> void:
	for mod in offer.scaled_modifiers():
		stats.add_modifier(mod)
	consume_level_up()


func consume_level_up() -> void:
	pending_level_ups = maxi(pending_level_ups - 1, 0)
