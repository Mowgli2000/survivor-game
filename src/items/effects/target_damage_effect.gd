class_name TargetDamageEffect
extends ItemEffect
## Damage scaled by the kind of target: more against elites and bosses, less against the rest (Executioner's mask).
## Applied to every hit of the owner through EnemyManager.damage_enemy, so it works for all weapons and items.

## Multiplier against elites, bosses and mini-bosses (1.5 = +50 %).
@export var vs_priority: float = 1.5
## Multiplier against every other enemy (0.8 = -20 %).
@export var vs_common: float = 0.8


func on_acquired(effects: ItemEffects) -> void:
	effects.enemies.set_target_damage_scales(effects.source, vs_priority, vs_common)


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if vs_priority <= 0.0 or vs_common <= 0.0:
		problems.append("multipliers must be > 0")
	return problems
