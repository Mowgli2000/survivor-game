class_name StatIds
## Identifiers, default values and bounds of every gameplay stat.
##
## Adding a stat: add a constant, a DEFAULTS entry, optional BOUNDS,
## and a localization key "STAT_<UPPER_ID>" in localization/strings.csv.

const MAX_HP := &"max_hp"
const HP_REGEN := &"hp_regen"            # HP per second
const ARMOR := &"armor"                  # see CombatMath.apply_armor
const MOVE_SPEED := &"move_speed"        # pixels per second
const DAMAGE := &"damage"                # multiplier (1.0 = 100%)
const ATTACK_SPEED := &"attack_speed"    # multiplier on weapon cooldown speed
const CRIT_CHANCE := &"crit_chance"      # added to weapon crit chance (0..1)
const CRIT_DAMAGE := &"crit_damage"      # damage multiplier on crit
const PROJECTILE_SPEED := &"projectile_speed"  # multiplier
const PROJECTILE_COUNT := &"projectile_count"  # added to weapon count
const PIERCE := &"pierce"                # added to weapon pierce
const KNOCKBACK := &"knockback"          # multiplier
const RANGE := &"range"                  # multiplier on weapon range
const AREA := &"area"                    # multiplier on slash, beam and explosion sizes
const PICKUP_RANGE := &"pickup_range"    # pixels
const DODGE := &"dodge"                  # chance to ignore a hit (0..0.6)
const LIFESTEAL := &"lifesteal"          # chance per damage dealt to heal 1 HP (capped per second)
const LUCK := &"luck"                    # +1 % per point to tier odds and item effect chances
const HARVEST := &"harvest"              # materials gained at the end of each wave

const DEFAULTS: Dictionary[StringName, float] = {
	MAX_HP: 100.0,
	HP_REGEN: 0.0,
	ARMOR: 0.0,
	MOVE_SPEED: 300.0,
	DAMAGE: 1.0,
	ATTACK_SPEED: 1.0,
	CRIT_CHANCE: 0.0,
	CRIT_DAMAGE: 1.5,
	PROJECTILE_SPEED: 1.0,
	PROJECTILE_COUNT: 0.0,
	PIERCE: 0.0,
	KNOCKBACK: 1.0,
	RANGE: 1.0,
	AREA: 1.0,
	PICKUP_RANGE: 120.0,
	DODGE: 0.0,
	LIFESTEAL: 0.0,
	LUCK: 0.0,
	HARVEST: 0.0,
}

## Stats stored as fractions (0.05) but shown as percentages (+5 %).
const SHOWN_AS_PERCENT: Array[StringName] = [CRIT_CHANCE, DODGE, LIFESTEAL]

## Stats used as whole numbers: scaled bonuses are rounded.
const INTEGER_STATS: Array[StringName] = [PROJECTILE_COUNT, PIERCE, LUCK, HARVEST]

## stat -> Vector2(min, max). Stats not listed are unbounded.
const BOUNDS: Dictionary[StringName, Vector2] = {
	MAX_HP: Vector2(1.0, INF),
	HP_REGEN: Vector2(0.0, INF),
	MOVE_SPEED: Vector2(50.0, INF),
	DAMAGE: Vector2(0.1, INF),
	ATTACK_SPEED: Vector2(0.1, INF),
	CRIT_CHANCE: Vector2(0.0, 1.0),
	CRIT_DAMAGE: Vector2(1.0, INF),
	PROJECTILE_SPEED: Vector2(0.1, INF),
	PROJECTILE_COUNT: Vector2(0.0, 5.0),  # +1 shot multiplies every weapon: capped
	PIERCE: Vector2(0.0, INF),
	KNOCKBACK: Vector2(0.0, INF),
	RANGE: Vector2(0.1, INF),
	AREA: Vector2(0.1, INF),
	PICKUP_RANGE: Vector2(0.0, INF),
	DODGE: Vector2(0.0, 0.6),
	LIFESTEAL: Vector2(0.0, 1.0),
	HARVEST: Vector2(0.0, INF),
}


static func is_valid(stat: StringName) -> bool:
	return DEFAULTS.has(stat)


static func localization_key(stat: StringName) -> String:
	return "STAT_" + String(stat).to_upper()
