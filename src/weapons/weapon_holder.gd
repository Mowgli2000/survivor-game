class_name WeaponHolder
extends Node
## Owns the weapons of a character and fires them when their cooldown is ready.
## Duplicates are allowed (one slot each). Two identical weapons of the same
## level (tier) merge into one of the next level, Brotato-style.

signal weapons_changed

## Slot limit read by is_full(); the shop enforces it, debug tools may go above.
var max_slots: int = 6

var _ctx: WeaponContext
var _slots: Array[WeaponSlot] = []


func setup(ctx: WeaponContext, p_max_slots: int = 6) -> void:
	_ctx = ctx
	max_slots = p_max_slots


## Always adds a new slot, even if the same weapon is already owned.
func add_weapon(data: WeaponData, level: int = 1) -> WeaponSlot:
	var slot := WeaponSlot.new(data, level)
	_slots.append(slot)
	weapons_changed.emit()
	return slot


func remove_weapon(index: int) -> void:
	if index < 0 or index >= _slots.size():
		return
	_slots.remove_at(index)
	weapons_changed.emit()


func is_full() -> bool:
	return _slots.size() >= max_slots


## Index of a slot holding `data` at `level` that can still go up a level, or -1.
func find_slot(data: WeaponData, level: int) -> int:
	for i in _slots.size():
		var slot := _slots[i]
		if slot.data == data and slot.level == level and not slot.is_max_level():
			return i
	return -1


## Index of another slot that can merge with slot `index`, or -1.
func find_merge_partner(index: int) -> int:
	if index < 0 or index >= _slots.size():
		return -1
	var slot := _slots[index]
	if slot.is_max_level():
		return -1
	for i in _slots.size():
		if i != index and _slots[i].data == slot.data and _slots[i].level == slot.level:
			return i
	return -1


## Slot `index` goes up one level and its partner is removed.
func merge(index: int) -> bool:
	var partner := find_merge_partner(index)
	if partner < 0:
		return false
	var slot := _slots[index]
	slot.set_level(slot.level + 1)
	_slots.remove_at(partner)
	weapons_changed.emit()
	return true


## One level up for slot `index` (buying an identical weapon while full).
func upgrade_slot(index: int) -> bool:
	if index < 0 or index >= _slots.size() or _slots[index].is_max_level():
		return false
	var slot := _slots[index]
	slot.set_level(slot.level + 1)
	weapons_changed.emit()
	return true


func get_slots() -> Array[WeaponSlot]:
	return _slots


func slot_count() -> int:
	return _slots.size()


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
