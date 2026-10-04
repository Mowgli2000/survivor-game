class_name WeaponSlot
extends RefCounted
## A weapon owned by the player: definition, tier (level 1..4), effective stats, cooldown.

var data: WeaponData
var level: int = 1
var stats: WeaponStats
var cooldown: float = 0.0
## Number of attacks made, for behaviors that alternate (e.g. "every 3rd hit").
var attacks: int = 0
## Position of the weapon around its owner, set by WeaponHolder (WeaponLayout).
var mount_offset := Vector2.ZERO
## Class rule multiplier on this weapon's damage (Mage: other families -25 %).
var damage_scale: float = 1.0


func _init(p_data: WeaponData, p_level: int = 1) -> void:
	data = p_data
	set_level(p_level)


func set_level(value: int) -> void:
	level = clampi(value, 1, data.max_level())
	stats = WeaponStats.compute(data, level)
	stats.damage *= damage_scale


func is_max_level() -> bool:
	return level >= data.max_level()
