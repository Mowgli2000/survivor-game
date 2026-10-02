class_name UpgradeData
extends Resource
## A level-up reward. Instances live in data/upgrades/.

@export var id: StringName
@export var name_key: String
## Relative chance of being offered.
@export var weight: float = 1.0
@export var modifiers: Array[StatModifier] = []
