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
## Every weapon sound a little lower (playtest: swings drowned the hits).
const WEAPON_SOUND_TRIM_DB := -7.0
const COPY_PHASE := 0.618
## Rapid fire build-up lost per second without firing (see WeaponData.ramp_speedup).
const RAMP_DECAY := 0.4
## Seconds without a shot before the build-up starts to fade.
const RAMP_HOLD := 0.4


var _ctx: WeaponContext
var _slots: Array[WeaponSlot] = []
## Run time (s) and, per weapon id, when a copy of it last attacked (see _physics_process).
var _clock: float = 0.0
var _last_copy_fire: Dictionary = {}


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
	# Every slot starts at its own phase (golden ratio of its index), copies or not: six melee
	# weapons never swing on the same frame, which also keeps the screen readable (dev, 2026-10-10).
	slot.cooldown = fposmod(_slots.size() * COPY_PHASE, 1.0) * slot.stats.cooldown
	_slots.append(slot)
	_refresh_mounts()
	weapons_changed.emit()
	return slot


func remove_weapon(index: int) -> void:
	if index < 0 or index >= _slots.size():
		return
	_slots[index].retired = true
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
	_slots[partner].retired = true
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
	_clock += delta
	for i in _slots.size():
		var slot := _slots[i]
		slot.cooldown -= delta * attack_speed
		if slot.ramp > 0.0 and _clock - slot.last_fired > RAMP_HOLD:
			slot.ramp = maxf(slot.ramp - delta * RAMP_DECAY, 0.0)
		if slot.cooldown > 0.0:
			continue
		# Copies of a weapon never attack together (the swings would draw one on top of the other, and an
		# idle spell makes them all ready at once): each waits its share of the cooldown after the last copy.
		if slot.copy_count > 1 and _clock - float(_last_copy_fire.get(slot.data.id, -1000.0)) 				< slot.stats.cooldown / attack_speed / slot.copy_count - 0.0001:
			continue
		if _ctx.enemies != null:
			_ctx.enemies.damage_weapon = slot.data.id
		slot.quiet = false
		if slot.data.behavior.fire(slot, _ctx):
			_last_copy_fire[slot.data.id] = _clock
			slot.attacks += 1
			weapon_fired.emit(i)
			if not slot.quiet:
				Audio.play(slot.data.fire_sound, slot.data.fire_volume_db + WEAPON_SOUND_TRIM_DB)
			# Keep the remainder so the fire rate does not depend on the frame rate.
			var wait := slot.stats.cooldown
			if slot.data.ramp_speedup > 0.0:
				slot.ramp = minf(slot.ramp + 1.0 / float(maxi(slot.data.ramp_shots, 1)), 1.0)
				slot.last_fired = _clock
				wait /= 1.0 + slot.ramp * slot.data.ramp_speedup
			slot.cooldown = maxf(slot.cooldown + wait, 0.0)
		else:
			slot.cooldown = 0.0


func _refresh_mounts() -> void:
	var seen := {}
	for i in _slots.size():
		_slots[i].mount_offset = WeaponLayout.mount_offset(i, _slots.size())
		var id := _slots[i].data.id
		_slots[i].copy_rank = int(seen.get(id, 0))
		seen[id] = _slots[i].copy_rank + 1
	for slot in _slots:
		slot.copy_count = int(seen[slot.data.id])
