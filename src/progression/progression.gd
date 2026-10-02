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


## Draws `count` distinct offers among: stat upgrades (weight = UpgradeData.weight),
## next level of each owned weapon below its max (weight = weapon_level_weight),
## and weapons not owned yet if a slot is free (weight = new_weapon_weight).
## `owned` maps WeaponData -> current level.
func roll_offers(stat_pool: Array[UpgradeData], weapon_pool: Array[WeaponData], owned: Dictionary,
		free_slots: int, count: int, rng: RandomNumberGenerator,
		new_weapon_weight: float = 1.0, weapon_level_weight: float = 1.5) -> Array[UpgradeOffer]:
	var candidates: Array[UpgradeOffer] = []
	var weights := PackedFloat32Array()
	for upgrade in stat_pool:
		candidates.append(UpgradeOffer.for_stat(upgrade))
		weights.append(upgrade.weight)
	for weapon in weapon_pool:
		if owned.has(weapon):
			var level: int = owned[weapon]
			if level < weapon.max_level():
				candidates.append(UpgradeOffer.for_weapon_level(weapon, level + 1))
				weights.append(weapon_level_weight)
		elif free_slots > 0:
			candidates.append(UpgradeOffer.for_new_weapon(weapon))
			weights.append(new_weapon_weight)
	var result: Array[UpgradeOffer] = []
	for index in WeightedPicker.pick_distinct(weights, count, rng):
		result.append(candidates[index])
	return result


## Applies a stat upgrade and consumes one pending level-up.
func apply_upgrade(upgrade: UpgradeData, stats: StatBlock) -> void:
	for mod in upgrade.modifiers:
		stats.add_modifier(mod)
	consume_level_up()


func consume_level_up() -> void:
	pending_level_ups = maxi(pending_level_ups - 1, 0)
