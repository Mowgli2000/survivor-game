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
## Extra price growth per wave after `late_price_from_wave` (late-game
## anti-snowball; 0 = none).
@export var late_price_growth_per_wave: float = 0.0
@export var late_price_from_wave: int = 10
@export var weapon_tier_price: Array[float] = [1.0, 1.9, 3.4, 6.0]
## Reroll cost = 1 + floor(wave x reroll_wave_factor)
## + max(1, floor(wave x reroll_step_factor)) x rerolls already done in this shop.
@export var reroll_wave_factor: float = 0.5
@export var reroll_step_factor: float = 0.5
## Rerolls that keep the linear cost above; each one after them costs
## `reroll_steep_factor` times the previous one (anti-spam; 0 / 1.0 = linear only).
@export var reroll_cheap_count: int = 0
@export var reroll_steep_factor: float = 1.0
## Each cheap reroll costs at least this times the previous one (early waves,
## where the linear step is only 1 material).
@export var reroll_cheap_min_growth: float = 1.0
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
## `luck` adds +1 % per point to each tier's chance (Brotato).
func roll_tier(wave: int, rng: RandomNumberGenerator, luck: float = 0.0) -> int:
	var luck_factor := maxf(1.0 + luck / 100.0, 0.0)
	for tier in range(Tiers.COUNT, 1, -1):
		if rng.randf() < tier_chance(tier, wave) * luck_factor:
			return tier
	return 1


func scaled_price(base: float, wave: int) -> int:
	return maxi(1, roundi(base * (1.0 + price_growth_per_wave * maxi(wave - 1, 0)
		+ late_price_growth_per_wave * maxi(wave - late_price_from_wave, 0))))


func weapon_price(weapon: WeaponData, tier: int, wave: int) -> int:
	return scaled_price(weapon.base_price * weapon_tier_price[clampi(tier, 1, Tiers.COUNT) - 1], wave)


func item_price(item: ItemData, wave: int) -> int:
	return scaled_price(item.base_price, wave)


func sell_price(weapon: WeaponData, tier: int, wave: int) -> int:
	return maxi(1, roundi(weapon_price(weapon, tier, wave) * sell_ratio))


## Cost of the next reroll after `rerolls_done` rerolls in the same shop.
func reroll_cost(wave: int, rerolls_done: int) -> int:
	var step := maxi(1, floori(wave * reroll_step_factor))
	var base := 1 + floori(wave * reroll_wave_factor)
	var cheap := mini(rerolls_done, reroll_cheap_count - 1) if reroll_cheap_count > 0 else rerolls_done
	var cost := base
	for i in range(1, cheap + 1):
		cost = maxi(base + step * i, ceili(cost * reroll_cheap_min_growth - 0.0001))
	if reroll_cheap_count <= 0 or rerolls_done < reroll_cheap_count:
		return cost
	return roundi(cost * pow(reroll_steep_factor, rerolls_done - reroll_cheap_count + 1))
