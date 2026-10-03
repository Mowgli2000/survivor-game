class_name WeaponFamilies
extends RefCounted
## Counts the owned weapons of each family (duplicates count, Brotato-style)
## and keeps the matching set bonus applied to the owner's stats. Pure logic:
## recomputed on WeaponHolder.weapons_changed, never per frame.

signal changed

var _holder: WeaponHolder
var _stats: StatBlock
var _families: Array[FamilyData] = []
var _counts: Dictionary[StringName, int] = {}
var _applied: Array[StatModifier] = []


func setup(holder: WeaponHolder, stats: StatBlock, families: Array[FamilyData]) -> void:
	_holder = holder
	_stats = stats
	_families = families
	_holder.weapons_changed.connect(_refresh)
	_refresh()


func get_families() -> Array[FamilyData]:
	return _families


func count(family_id: StringName) -> int:
	return _counts.get(family_id, 0)


## Bonus currently applied for `family`, or null.
func active_bonus(family: FamilyData) -> FamilyBonus:
	return family.bonus_for(count(family.id))


func _refresh() -> void:
	for mod in _applied:
		_stats.remove_modifier(mod)
	_applied.clear()
	_counts.clear()
	for slot in _holder.get_slots():
		for family_id in slot.data.families:
			_counts[family_id] = count(family_id) + 1
	for family in _families:
		var bonus := family.bonus_for(count(family.id))
		if bonus == null:
			continue
		for mod in bonus.modifiers:
			_stats.add_modifier(mod)
			_applied.append(mod)
	changed.emit()
