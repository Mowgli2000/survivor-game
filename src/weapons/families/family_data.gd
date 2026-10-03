class_name FamilyData
extends Resource
## A weapon family (blades, guns...) with set bonuses. Instances live in data/families/.

@export var id: StringName
@export var name_key: String
@export var color: Color = Color.WHITE
## Tiers in rising `count` order.
@export var bonuses: Array[FamilyBonus] = []


## Highest tier reached with `owned` weapons, or null.
func bonus_for(owned: int) -> FamilyBonus:
	var best: FamilyBonus = null
	for bonus in bonuses:
		if bonus != null and owned >= bonus.count:
			best = bonus
	return best
