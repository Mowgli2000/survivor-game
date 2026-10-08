class_name ItemEffect
extends Resource
## What an item does beyond stat modifiers (strategy, like weapon behaviors).
## ItemEffects duplicates the resource for each owned copy, so subclasses may
## keep state (counters, applied modifiers) in plain variables.


## The copy was bought.
func on_acquired(_effects: ItemEffects) -> void:
	pass


func on_enemy_killed(_effects: ItemEffects, _data: EnemyData, _pos: Vector2, _elite: bool) -> void:
	pass


func on_wave_ended(_effects: ItemEffects, _wave: int) -> void:
	pass


func on_tick(_effects: ItemEffects, _delta: float) -> void:
	pass


## Bonus a copy bought now would give with the current build (shown on shop
## cards), or empty when the effect has no such readable bonus. Never mutates.
func preview_modifiers(_stats: StatBlock, _weapons: WeaponHolder) -> Array[StatModifier]:
	return []


## Problems with the data (empty when valid). Checked by the content tests.
func validate() -> PackedStringArray:
	return PackedStringArray()
