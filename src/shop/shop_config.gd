class_name ShopConfig
extends Resource
## Shop tuning (data/shop/). Pure functions for tier rolls, prices and reroll
## costs, shared by the shop and the level-up screen. Arrays: index 0 = tier I.

@export var id: StringName
@export var slot_count: int = 4
## Chance that a slot offers a weapon instead of an item.
@export_range(0.0, 1.0) var weapon_chance: float = 0.35
@export var starting_materials: int = 30
## price = base * (1 + growth * (wave - 1))
@export var price_growth_per_wave: float = 0.10
@export var weapon_tier_price: Array[float] = [1.0, 1.9, 3.4, 6.0]
## Selling a weapon gives back this fraction of its current price.
@export var sell_ratio: float = 0.25

@export_group("Tier odds")
@export var tier_min_wave: Array[int] = [1, 2, 4, 8]
@export var tier_base_chance: Array[float] = [0.0, 0.10, 0.03, 0.01]
@export var tier_chance_per_wave: Array[float] = [0.0, 0.05, 0.025, 0.01]
@export var tier_max_chance: Array[float] = [0.0, 0.60, 0.25, 0.08]


## Chance to roll `tier` (2..COUNT) on `wave`. Tier I is the fallback: 0 here.
func tier_chance(tier: int, wave: int) -> float:
	if tier <= 1 or tier > Tiers.COUNT:
		return 0.0
	var i := tier - 1
	if wave < tier_min_wave[i]:
		return 0.0
	return minf(tier_base_chance[i] + tier_chance_per_wave[i] * (wave - tier_min_wave[i]), tier_max_chance[i])


## Highest tier first; tier I when every roll fails.
func roll_tier(wave: int, rng: RandomNumberGenerator) -> int:
	for tier in range(Tiers.COUNT, 1, -1):
		if rng.randf() < tier_chance(tier, wave):
			return tier
	return 1


func scaled_price(base: float, wave: int) -> int:
	return maxi(1, roundi(base * (1.0 + price_growth_per_wave * maxi(wave - 1, 0))))


func weapon_price(weapon: WeaponData, tier: int, wave: int) -> int:
	return scaled_price(weapon.base_price * weapon_tier_price[clampi(tier, 1, Tiers.COUNT) - 1], wave)


func item_price(item: ItemData, wave: int) -> int:
	return scaled_price(item.base_price, wave)


func sell_price(weapon: WeaponData, tier: int, wave: int) -> int:
	return maxi(1, roundi(weapon_price(weapon, tier, wave) * sell_ratio))


## Cost of the next reroll after `rerolls_done` rerolls in the same shop.
func reroll_cost(wave: int, rerolls_done: int) -> int:
	var half := floori(wave / 2.0)
	return 1 + half + maxi(1, half) * rerolls_done
