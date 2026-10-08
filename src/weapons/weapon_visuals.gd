class_name WeaponVisuals
extends Node2D
## Draws the owner's weapons around it (Brotato-style): each one at its mount
## (WeaponLayout), turned toward the nearest enemy in its range (else the walking
## direction), with recoil + muzzle flash (ranged) or a quick swing (melee) when
## WeaponHolder reports an attack. One node, one _draw for all weapons (6 at most).

## Turning speed toward the aimed direction (1/s, used as a lerp factor).
const AIM_SPEED := 18.0
## Drawn length of a weapon (the icon's width), in px. The dev wants the floating
## weapons this size; only the UI icons grow (diagonal art, see tools/art/make_icon.gd).
const SIZE := 60.0
const RECOIL := 7.0
const KICK_TIME := 0.12
const SWING_TIME := 0.18
## Melee swing (cartoon: wind-up, strike, follow-through), seconds per kind of weapon.
const MELEE_TIME := 0.34
const MELEE_TIME_THRUST := 0.26
const MELEE_TIME_HEAVY := 0.46
## Half of the melee swing, in radians.
const SWING_ARC := 1.1
## Afterimages of a swinging weapon: fading ghosts along its path.
const GHOSTS := 3
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
	# Flashes are plain additive circles, drawn by their own child.
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
		var reach := MeleeArcBehavior.reach_multiplier(_owner.stats) if _is_melee(slot) else range_multiplier
		var target := _enemies.find_nearest(mount, slot.stats.attack_range * reach) \
			if _enemies != null else -1
		var wanted := _aim[i]
		if target >= 0:
			wanted = (_enemies.get_enemy(target).position - mount).angle()
		elif moving:
			wanted = _owner.velocity.angle()
		_aim[i] = lerp_angle(_aim[i], wanted, minf(AIM_SPEED * delta, 1.0))
		var duration := melee_time(slot.data.slash_style) if _is_melee(slot) else KICK_TIME
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
		var squash := Vector2.ONE
		if _is_melee(slot):
			if _kick[i] > 0.0:
				var progress := 1.0 - _kick[i]
				var pose := melee_pose(progress, slot.data.slash_style)
				angle += pose.x
				pos += Vector2.from_angle(_aim[i]) * pose.y
				squash = Vector2(pose.z, 2.0 - pose.z)
				_draw_ghosts(slot, icon, progress)
		else:
			pos -= Vector2.from_angle(angle) * RECOIL * _kick[i]
		_draw_weapon(slot, icon, angle, pos, squash, Color.WHITE)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## One weapon (or one afterimage of it) at `angle` / `pos`; `squash` stretches it along
## its length (x) and squeezes it across (y). Mirrored when aimed left, never upside down.
func _draw_weapon(slot: WeaponSlot, icon: Texture2D, angle: float, pos: Vector2, squash: Vector2,
		tint: Color) -> void:
	var flip := -1.0 if absf(angle_difference(0.0, angle)) > PI * 0.5 else 1.0
	if slot.data.icon_diagonal:
		# Diagonal art (tip up-right): turned back to horizontal, same drawn length.
		var diagonal_scale := SIZE * slot.data.float_scale / (icon.get_width() * sqrt(2.0))
		draw_set_transform_matrix(Transform2D(angle, pos)
			* Transform2D(0.0, Vector2(diagonal_scale * squash.x, diagonal_scale * flip * squash.y), 0.0, Vector2.ZERO)
			* Transform2D(PI / 4.0, Vector2.ZERO))
	else:
		var scale_factor := SIZE * slot.data.float_scale / icon.get_width()
		draw_set_transform(pos, angle, Vector2(scale_factor * squash.x, scale_factor * flip * squash.y))
	draw_texture(icon, -icon.get_size() * 0.5, tint)


## Fading copies of a weapon behind its blade while it strikes (the speed smear).
func _draw_ghosts(slot: WeaponSlot, icon: Texture2D, progress: float) -> void:
	var strike := strike_amount(progress, slot.data.slash_style)
	if strike <= 0.0:
		return
	var aim := _aim[_holder.get_slots().find(slot)]
	for g in range(GHOSTS, 0, -1):
		var behind := maxf(progress - g * 0.045, 0.0)
		var pose := melee_pose(behind, slot.data.slash_style)
		var alpha := 0.32 * strike * (1.0 - float(g - 1) / GHOSTS)
		_draw_weapon(slot, icon, aim + pose.x, slot.mount_offset + Vector2.from_angle(aim) * pose.y,
			Vector2(pose.z, 2.0 - pose.z), Color(1.0, 1.0, 1.0, alpha))


## Seconds a melee swing lasts for a slash style (a thrust is quick, a smash is slow).
static func melee_time(style: int) -> float:
	match style:
		WeaponData.SlashStyle.THRUST:
			return MELEE_TIME_THRUST
		WeaponData.SlashStyle.HEAVY, WeaponData.SlashStyle.SMASH:
			return MELEE_TIME_HEAVY
	return MELEE_TIME


## Pose of a melee weapon `progress` (0..1) into its swing, as Vector3(angle offset in
## radians, push along the aim in px, stretch along the blade). Three beats:
## wind-up (pull back, squash), strike (fast ease-out, stretch), follow-through (overshoot,
## a damped wobble back to rest). A thrust pulls back then lunges instead of turning.
static func melee_pose(progress: float, style: int) -> Vector3:
	var p := clampf(progress, 0.0, 1.0)
	var heavy := style == WeaponData.SlashStyle.HEAVY or style == WeaponData.SlashStyle.SMASH
	var wind_end := 0.42 if heavy else 0.22
	var strike_end := 0.62 if heavy else 0.5
	if style == WeaponData.SlashStyle.THRUST:
		if p < wind_end:
			var w := ease_out(p / wind_end)
			return Vector3(0.0, -9.0 * w, 1.0 - 0.1 * w)
		if p < strike_end:
			var s := ease_out((p - wind_end) / (strike_end - wind_end))
			return Vector3(0.0, lerpf(-9.0, 30.0, s), 0.9 + 0.35 * s)
		var r := (p - strike_end) / (1.0 - strike_end)
		return Vector3(0.0, 30.0 * (1.0 - ease_out(r)), 1.25 - 0.25 * ease_out(r))
	var back := -SWING_ARC * (0.9 if heavy else 0.55)
	var front := SWING_ARC * (1.0 if heavy else 1.15)
	if p < wind_end:
		var w := ease_out(p / wind_end)
		return Vector3(lerpf(0.0, back, w), -4.0 * w, 1.0 - 0.12 * w)
	if p < strike_end:
		var s := ease_out((p - wind_end) / (strike_end - wind_end))
		return Vector3(lerpf(back, front, s), lerpf(-4.0, 10.0, s), 0.88 + 0.32 * s)
	var r := (p - strike_end) / (1.0 - strike_end)
	var settle := exp(-4.5 * r) * cos(r * 9.0)
	return Vector3(front * settle, 10.0 * (1.0 - ease_out(r)), 1.2 - 0.2 * ease_out(r))


## Seconds from the start of a melee swing to its strike (the wind-up): the slash streak
## and the hit start then.
static func strike_delay(style: int) -> float:
	var heavy := style == WeaponData.SlashStyle.HEAVY or style == WeaponData.SlashStyle.SMASH
	return melee_time(style) * (0.42 if heavy else 0.22)


## How much the weapon is mid-strike (0..1): drives the afterimages.
static func strike_amount(progress: float, style: int) -> float:
	var heavy := style == WeaponData.SlashStyle.HEAVY or style == WeaponData.SlashStyle.SMASH
	var from := 0.42 if heavy else 0.22
	var to := 0.72 if heavy else 0.6
	if progress < from or progress > to:
		return 0.0
	return sin(PI * (progress - from) / (to - from))


static func ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


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
