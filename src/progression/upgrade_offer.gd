class_name UpgradeOffer
extends RefCounted
## One card of the level-up screen: a stat upgrade at a tier (I..IV).
## The tier multiplies the upgrade's modifiers (Tiers.UPGRADE_SCALE).

var upgrade: UpgradeData
var tier: int = 1
## Class rule (CharacterData.upgrade_scale): multiplies the card on top of its tier.
var bonus_scale: float = 1.0


static func for_stat(p_upgrade: UpgradeData, p_tier: int = 1) -> UpgradeOffer:
	var offer := UpgradeOffer.new()
	offer.upgrade = p_upgrade
	offer.tier = clampi(p_tier, 1, Tiers.COUNT)
	return offer


## New modifiers scaled by the tier (the UpgradeData resource is never changed).
func scaled_modifiers() -> Array[StatModifier]:
	var scale := Tiers.UPGRADE_SCALE[tier - 1] * bonus_scale
	var result: Array[StatModifier] = []
	for mod in upgrade.modifiers:
		var scaled := StatModifier.new()
		scaled.stat = mod.stat
		scaled.flat = mod.flat * scale
		scaled.percent = mod.percent * scale
		if mod.stat in StatIds.INTEGER_STATS:
			scaled.flat = roundf(scaled.flat)
		result.append(scaled)
	return result
