class_name UpgradeOffer
extends RefCounted
## One card of the level-up screen: a stat upgrade, a new weapon, or the next
## level of an owned weapon.

enum Kind { STAT, NEW_WEAPON, WEAPON_LEVEL }

var kind: Kind
var upgrade: UpgradeData
var weapon: WeaponData
## Level of the weapon after choosing this offer (1 for a new weapon).
var level: int = 1


static func for_stat(p_upgrade: UpgradeData) -> UpgradeOffer:
	var offer := UpgradeOffer.new()
	offer.kind = Kind.STAT
	offer.upgrade = p_upgrade
	return offer


static func for_new_weapon(p_weapon: WeaponData) -> UpgradeOffer:
	var offer := UpgradeOffer.new()
	offer.kind = Kind.NEW_WEAPON
	offer.weapon = p_weapon
	offer.level = 1
	return offer


static func for_weapon_level(p_weapon: WeaponData, p_level: int) -> UpgradeOffer:
	var offer := UpgradeOffer.new()
	offer.kind = Kind.WEAPON_LEVEL
	offer.weapon = p_weapon
	offer.level = p_level
	return offer
