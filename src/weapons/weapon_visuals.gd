class_name WeaponVisuals
extends Node2D
## Draws the owner's weapons around it (Brotato-style): each one at its mount
## (WeaponLayout), turned toward the nearest enemy in its range (else the walking
## direction), with recoil + muzzle flash (ranged) or a quick swing (melee) when
## WeaponHolder reports an attack. One node, one _draw for all weapons (6 at most).
## The outline shader colors each weapon's outline with its tier color.

const OUTLINE_SHADER := preload("res://src/weapons/weapon_outline.gdshader")
## Turning speed toward the aimed direction (1/s, used as a lerp factor).
const AIM_SPEED := 18.0
## Drawn length of a weapon (the icon's width), in px.
const SIZE := 70.0
const RECOIL := 7.0
const KICK_TIME := 0.12
const SWING_TIME := 0.18
## Half of the melee swing, in radians.
const SWING_ARC := 1.1
const FLASH_RADIUS := 9.0

var _holder: WeaponHolder
var _enemies: EnemyManager
var _owner: Player
var _aim := PackedFloat32Array()
var _kick := PackedFloat32Array()
var _flashes: _MuzzleFlashes


func _ready() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader_material := ShaderMaterial.new()
	shader_material.shader = OUTLINE_SHADER
	material = shader_material
	# Flashes are plain additive circles: drawn by a child without the outline shader.
	_flashes = _MuzzleFlashes.new()
	_flashes.visuals = self
	add_child(_flashes)


func setup(holder: WeaponHolder, enemies: EnemyManager, owner: Player) -> void:
	_holder = holder
	_enemies = enemies
	_owner = owner
	_holder.weapons_changed.connect(_resize)
	_holder.weapon_fired.connect(_on_weapon_fired)
	_resize()


## Current aim of weapon `index`, in radians.
func aim_angle(index: int) -> float:
	return _aim[index] if index < _aim.size() else 0.0


## Recoil / swing progress of weapon `index`: 1 just after an attack, 0 at rest.
func kick(index: int) -> float:
	return _kick[index] if index < _kick.size() else 0.0


func _resize() -> void:
	var count := _holder.slot_count()
	_aim.resize(count)
	_kick.resize(count)


func _on_weapon_fired(index: int) -> void:
	if index < _kick.size():
		_kick[index] = 1.0


func _process(delta: float) -> void:
	if _holder == null:
		return
	var slots := _holder.get_slots()
	if slots.size() != _aim.size():
		_resize()
	var origin := _owner.global_position
	var range_multiplier := _owner.stats.get_value(StatIds.RANGE)
	var moving := _owner.velocity.length_squared() > 1.0
	for i in slots.size():
		var slot := slots[i]
		var mount := origin + slot.mount_offset
		var target := _enemies.find_nearest(mount, slot.stats.attack_range * range_multiplier) \
			if _enemies != null else -1
		var wanted := _aim[i]
		if target >= 0:
			wanted = (_enemies.get_enemy(target).position - mount).angle()
		elif moving:
			wanted = _owner.velocity.angle()
		_aim[i] = lerp_angle(_aim[i], wanted, minf(AIM_SPEED * delta, 1.0))
		var duration := SWING_TIME if _is_melee(slot) else KICK_TIME
		_kick[i] = maxf(_kick[i] - delta / duration, 0.0)
	queue_redraw()
	_flashes.queue_redraw()


func _draw() -> void:
	if _holder == null:
		return
	var slots := _holder.get_slots()
	for i in mini(slots.size(), _aim.size()):
		var slot := slots[i]
		var icon := slot.data.icon
		if icon == null:
			continue
		var angle := _aim[i]
		var pos := slot.mount_offset
		if _is_melee(slot):
			if _kick[i] > 0.0:
				angle += lerpf(-SWING_ARC, SWING_ARC, 1.0 - _kick[i])
		else:
			pos -= Vector2.from_angle(angle) * RECOIL * _kick[i]
		var scale_factor := SIZE / icon.get_width()
		# Aiming left: mirror vertically so the weapon is not upside down.
		var flip := -1.0 if absf(angle_difference(0.0, angle)) > PI * 0.5 else 1.0
		draw_set_transform(pos, angle, Vector2(scale_factor, scale_factor * flip))
		draw_texture(icon, -icon.get_size() * 0.5, Tiers.color(slot.level))
	draw_set_transform(Vector2.ZERO)


func _draw_flashes(canvas: CanvasItem) -> void:
	if _holder == null:
		return
	var slots := _holder.get_slots()
	for i in mini(slots.size(), _kick.size()):
		var slot := slots[i]
		var k := _kick[i]
		if k < 0.4 or _is_melee(slot) or slot.data.icon == null:
			continue
		var muzzle := slot.mount_offset + Vector2.from_angle(_aim[i]) * WeaponLayout.BARREL
		canvas.draw_circle(muzzle, FLASH_RADIUS * k, Color(slot.data.color, k))
		canvas.draw_circle(muzzle, FLASH_RADIUS * 0.45 * k, Color(1, 1, 1, k))


static func _is_melee(slot: WeaponSlot) -> bool:
	return slot.data.behavior is MeleeArcBehavior


class _MuzzleFlashes:
	extends Node2D
	var visuals: WeaponVisuals

	func _ready() -> void:
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = additive

	func _draw() -> void:
		visuals._draw_flashes(self)
