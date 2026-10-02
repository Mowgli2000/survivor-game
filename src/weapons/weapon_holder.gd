class_name WeaponHolder
extends Node
## Owns the weapons of a character and fires them when their cooldown is ready.

signal weapons_changed

var _ctx: WeaponContext
var _slots: Array[WeaponSlot] = []


func setup(ctx: WeaponContext) -> void:
	_ctx = ctx


## Adds a weapon (or returns the existing slot if it is already owned).
func add_weapon(data: WeaponData, level: int = 1) -> WeaponSlot:
	var existing := get_slot(data)
	if existing != null:
		return existing
	var slot := WeaponSlot.new(data, level)
	_slots.append(slot)
	weapons_changed.emit()
	return slot


## Returns false if the weapon is not owned or already at its max level.
func level_up(data: WeaponData) -> bool:
	var slot := get_slot(data)
	if slot == null or slot.is_max_level():
		return false
	slot.set_level(slot.level + 1)
	weapons_changed.emit()
	return true


func get_slot(data: WeaponData) -> WeaponSlot:
	for slot in _slots:
		if slot.data == data:
			return slot
	return null


func get_slots() -> Array[WeaponSlot]:
	return _slots


func slot_count() -> int:
	return _slots.size()


## WeaponData -> current level.
func owned_levels() -> Dictionary:
	var result := {}
	for slot in _slots:
		result[slot.data] = slot.level
	return result


func _physics_process(delta: float) -> void:
	if _ctx == null:
		return
	var attack_speed := _ctx.stats.get_value(StatIds.ATTACK_SPEED)
	for slot in _slots:
		slot.cooldown -= delta * attack_speed
		if slot.cooldown > 0.0:
			continue
		if slot.data.behavior.fire(slot, _ctx):
			slot.attacks += 1
			# Keep the remainder so the fire rate does not depend on the frame rate.
			slot.cooldown = maxf(slot.cooldown + slot.stats.cooldown, 0.0)
		else:
			slot.cooldown = 0.0
