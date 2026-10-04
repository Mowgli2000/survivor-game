class_name FamilyCountStatEffect
extends ItemEffect
## `modifier` applied once per owned weapon of `family` (duplicates count),
## kept up to date when weapons change. Mage rule "Arcane affinity".

@export var family: StringName = &"energy"
@export var modifier: StatModifier

var _player: Player
var _applied: Array[StatModifier] = []


func on_acquired(effects: ItemEffects) -> void:
	_player = effects.player
	_player.weapons.weapons_changed.connect(_update)
	_update()


func applied_count() -> int:
	return _applied.size()


func _update() -> void:
	for mod in _applied:
		_player.stats.remove_modifier(mod)
	_applied.clear()
	for slot in _player.weapons.get_slots():
		if family in slot.data.families:
			_player.stats.add_modifier(modifier)
			_applied.append(modifier)


func validate() -> PackedStringArray:
	return PackedStringArray(["modifier is missing"]) if modifier == null else PackedStringArray()
