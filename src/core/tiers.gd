class_name Tiers
## Rarity tiers shared by weapons, items, shop slots and level-up cards
## (Brotato-style I..IV). Tier numbers are 1-based.

const COUNT := 4
const COLORS: Array[Color] = [
	Color(0.78, 0.8, 0.86),   # I   grey
	Color(0.35, 0.65, 1.0),   # II  blue
	Color(0.75, 0.4, 1.0),    # III purple
	Color(1.0, 0.3, 0.35),    # IV  red
]
const ROMAN: Array[String] = ["I", "II", "III", "IV"]
## Level-up bonus multiplier per tier.
const UPGRADE_SCALE: Array[float] = [1.0, 1.6, 2.4, 3.2]


static func color(tier: int) -> Color:
	return COLORS[clampi(tier, 1, COUNT) - 1]


static func roman(tier: int) -> String:
	return ROMAN[clampi(tier, 1, COUNT) - 1]
