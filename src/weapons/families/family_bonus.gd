class_name FamilyBonus
extends Resource
## One tier of a weapon family: owning at least `count` weapons of the family
## applies these modifiers (only the highest reached tier applies).

@export var count: int = 2
@export var modifiers: Array[StatModifier] = []
