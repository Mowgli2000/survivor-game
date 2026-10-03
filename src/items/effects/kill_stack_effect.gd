class_name KillStackEffect
extends ItemEffect
## Grows with kills: applies `modifier` once more every `kills_per_stack` kills,
## up to `max_stacks` (for the rest of the run).

@export var kills_per_stack: int = 20
@export var max_stacks: int = 60
@export var modifier: StatModifier

var _kills: int = 0
var _stacks: int = 0


func on_enemy_killed(effects: ItemEffects, _data: EnemyData, _pos: Vector2, _elite: bool) -> void:
	if _stacks >= max_stacks or modifier == null:
		return
	_kills += 1
	if _kills >= kills_per_stack:
		_kills = 0
		_stacks += 1
		effects.stats.add_modifier(modifier)


func validate() -> PackedStringArray:
	if modifier == null or kills_per_stack <= 0:
		return PackedStringArray(["needs a modifier and kills_per_stack > 0"])
	return PackedStringArray()
