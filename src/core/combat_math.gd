class_name CombatMath
## Pure damage formulas. No state, no nodes: everything here is unit tested.


## Size multiplier of a zone (explosion radius, swing size, beam width) for a Zone stat of `raw`: the first points
## count in full below 1, the bonus above it counts for half (+100 % Zone = x1.5, +200 % = x2), so a huge Zone
## stat never fills the screen (dev, 2026-10-11).
static func area_scale(raw: float) -> float:
	return raw if raw <= 1.0 else 1.0 + (raw - 1.0) * AREA_BONUS_SHARE


const AREA_BONUS_SHARE := 0.5


## `roll` is a random value in [0, 1).
static func is_crit(crit_chance: float, roll: float) -> bool:
	return roll < crit_chance


static func outgoing_damage(base_damage: float, damage_mult: float, crit: bool, crit_mult: float) -> float:
	var damage := base_damage * damage_mult
	if crit:
		damage *= crit_mult
	return damage


## Positive armor reduces damage with diminishing returns (10 armor = -9 %, 100 armor = -50 %).
## Negative armor increases damage symmetrically. A hit always deals at least 1.
static func apply_armor(damage: float, armor: float) -> float:
	if damage <= 0.0:
		return 0.0
	var factor: float
	if armor >= 0.0:
		factor = 100.0 / (100.0 + armor)
	else:
		factor = 2.0 - 100.0 / (100.0 - armor)
	return maxf(damage * factor, 1.0)
