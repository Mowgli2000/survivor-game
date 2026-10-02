class_name UpgradeOffer
extends RefCounted
## One card of the level-up screen: a stat upgrade.

var upgrade: UpgradeData


static func for_stat(p_upgrade: UpgradeData) -> UpgradeOffer:
	var offer := UpgradeOffer.new()
	offer.upgrade = p_upgrade
	return offer
