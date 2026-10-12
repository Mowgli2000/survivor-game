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
## Copies of the same weapon (same id) held by the player: how many, and the rank of this one (0 = the
## first). Set by WeaponHolder. Copies attack out of step (cooldown / count apart) and aim at different
## enemies (the rank-th nearest), so a second copy is seen and not hidden behind the first.
var copy_rank: int = 0
var copy_count: int = 1
## Set when the weapon leaves the player (sold, merged): what it left on the field (orbiting blades) goes with it.
var retired: bool = false
## A behavior sets it during `fire` when it only did upkeep (no attack worth a sound).
var quiet: bool = false
## Rapid fire build-up, 0..1 (see WeaponData.ramp_speedup).
var ramp: float = 0.0
## `WeaponHolder` clock of the last shot (the build-up only fades after a pause).
var last_fired: float = -1000.0


func _init(p_data: WeaponData, p_level: int = 1) -> void:
	data = p_data
	set_level(p_level)


func set_level(value: int) -> void:
	level = clampi(value, 1, data.max_level())
	stats = WeaponStats.compute(data, level)
	stats.damage *= damage_scale


func is_max_level() -> bool:
	return level >= data.max_level()
