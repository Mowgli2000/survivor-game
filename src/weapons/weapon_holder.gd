class_name WeaponHolder
extends Node
## Owns the weapons of a character and fires them when their cooldown is ready.
## Duplicates are allowed (one slot each). Two identical weapons of the same
## level (tier) merge into one of the next level, Brotato-style.

signal weapons_changed
## A weapon attacked (index in get_slots()). Used by WeaponVisuals for recoil / swing.
signal weapon_fired(index: int)

## Slot limit read by is_full(); the shop enforces it, debug tools may go above.
var max_slots: int = 6
## Class rule (CharacterData): weapons outside `favored_family` deal
## `off_family_scale` times their damage. Empty family: no rule.
var favored_family: StringName = &""
var off_family_scale: float = 1.0

## Share of its cooldown a new copy of an owned weapon waits before its first attack, per
## copy already owned (golden ratio: any number of copies spread evenly).
const COPY_PHASE := 0.618

var _ctx: WeaponContext
var _slots: Array[WeaponSlot] = []


func setup(ctx: WeaponContext, p_max_slots: int = 6) -> void:
	_ctx = ctx
	max_slots = p_max_slots


## Always adds a new slot, even if the same weapon is already owned.
func add_weapon(data: WeaponData, level: int = 1) -> WeaponSlot:
	var slot := WeaponSlot.new(data, level)
	if favored_family != &"" and not favored_family in data.families:
		slot.damage_scale = off_family_scale
		slot.set_level(level)
	# Copies of one weapon attack out of step: melee swings come out of the player's
	# center, so copies firing on the same frame drew one single overlapping swing.
	var copies := 0
	for other in _slots:
		if other.data == data:
			copies += 1
	slot.cooldown = fposmod(copies * COPY_PHASE, 1.0) * slot.stats.cooldown
	_slots.append(slot)
	_refresh_mounts()
	weapons_changed.emit()
	return slot


func remove_weapon(index: int) -> void:
	if index < 0 or index >= _slots.size():
		return
	_slots.remove_at(index)
	_refresh_mounts()
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
	_refresh_mounts()
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
	var player := _ctx.owner as Player
	if player != null and player.is_dead:
		return
	if _ctx.enemies != null:
		_ctx.enemies.damage_source = _ctx.source
	var attack_speed := _ctx.stats.get_value(StatIds.ATTACK_SPEED)
	for i in _slots.size():
		var slot := _slots[i]
		slot.cooldown -= delta * attack_speed
		if slot.cooldown > 0.0:
			continue
		if _ctx.enemies != null:
			_ctx.enemies.damage_weapon = slot.data.id
		if slot.data.behavior.fire(slot, _ctx):
			slot.attacks += 1
			weapon_fired.emit(i)
			Audio.play(slot.data.fire_sound, slot.data.fire_volume_db)
			# Keep the remainder so the fire rate does not depend on the frame rate.
			slot.cooldown = maxf(slot.cooldown + slot.stats.cooldown, 0.0)
		else:
			slot.cooldown = 0.0


func _refresh_mounts() -> void:
	for i in _slots.size():
		_slots[i].mount_offset = WeaponLayout.mount_offset(i, _slots.size())
