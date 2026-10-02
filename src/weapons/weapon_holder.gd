class_name WeaponHolder
extends Node
## Owns the weapons of a character and fires them when their cooldown is ready.

class WeaponSlot:
	var data: WeaponData
	var cooldown: float = 0.0

var _ctx: WeaponContext
var _slots: Array[WeaponSlot] = []


func setup(ctx: WeaponContext) -> void:
	_ctx = ctx


func add_weapon(data: WeaponData) -> void:
	var slot := WeaponSlot.new()
	slot.data = data
	_slots.append(slot)


func get_weapons() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for slot in _slots:
		result.append(slot.data)
	return result


func _physics_process(delta: float) -> void:
	if _ctx == null:
		return
	var attack_speed := _ctx.stats.get_value(StatIds.ATTACK_SPEED)
	for slot in _slots:
		slot.cooldown -= delta * attack_speed
		if slot.cooldown > 0.0:
			continue
		if slot.data.behavior.fire(slot.data, _ctx):
			# Keep the remainder so the fire rate does not depend on the frame rate.
			slot.cooldown = maxf(slot.cooldown + slot.data.cooldown, 0.0)
		else:
			slot.cooldown = 0.0
