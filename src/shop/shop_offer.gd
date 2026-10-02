class_name ShopOffer
extends RefCounted
## One shop slot: a weapon or an item at a tier, its current price and state.

var weapon: WeaponData
var item: ItemData
## Weapon tier, or the item's own tier.
var tier: int = 1
var price: int = 0
## Kept (and re-priced) by the next shop; never replaced by a reroll.
var locked: bool = false
## Bought: the slot stays empty until the next reroll or shop.
var sold: bool = false


func is_weapon() -> bool:
	return weapon != null
