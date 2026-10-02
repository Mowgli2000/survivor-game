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


## Draws `count` distinct upgrades from `pool`, weighted by UpgradeData.weight.
func roll_choices(pool: Array[UpgradeData], count: int, rng: RandomNumberGenerator) -> Array[UpgradeData]:
	var weights := PackedFloat32Array()
	for upgrade in pool:
		weights.append(upgrade.weight)
	var result: Array[UpgradeData] = []
	for index in WeightedPicker.pick_distinct(weights, count, rng):
		result.append(pool[index])
	return result


func apply_upgrade(upgrade: UpgradeData, stats: StatBlock) -> void:
	for mod in upgrade.modifiers:
		stats.add_modifier(mod)
	pending_level_ups = maxi(pending_level_ups - 1, 0)
