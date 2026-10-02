class_name StatModifier
extends Resource
## A change to one stat: final = (base + sum(flat)) * (1 + sum(percent)).

@export var stat: StringName = StatIds.DAMAGE
@export var flat: float = 0.0
## 0.1 = +10 %
@export var percent: float = 0.0
