class_name Enemy
extends Node2D
## Passive enemy: data, runtime state and placeholder visual. Moved, damaged and
## ticked by EnemyManager (no _process here, see ADR 0002).
## Visual: animated sprite sheet (frame advanced by EnemyManager, redrawn only
## when the frame or facing changes), or the baked neon placeholder (EnemyArt)
## when the type has no sprite. Hit flash and statuses only change `self_modulate`.

const FLASH_TIME := 0.08
const FLASH_TINT := Color(3.0, 3.0, 3.0)
const BURN_TINT := Color(1.8, 1.0, 0.55)
const SLOW_TINT := Color(0.55, 0.9, 1.8)
## Sprite height in px per px of collision radius.
const SPRITE_HEIGHT_PER_RADIUS := 5.0
## Feet sit this fraction of the radius below the enemy center.
const SPRITE_FOOT := 0.8

var data: EnemyData
var elite: bool = false
var hp: float = 0.0
var max_hp: float = 0.0
var radius: float = 16.0
var knockback := Vector2.ZERO
## Last separation push, reused on the ticks where it is not recomputed.
var separation := Vector2.ZERO
var flash: float = 0.0
var fire_timer: float = 0.0
## +1 or -1: direction in which a ranged enemy circles the player.
var strafe_sign: float = 1.0

var burn_dps: float = 0.0
var burn_time: float = 0.0
## Burn damage not yet shown as a damage number.
var burn_pending: float = 0.0
## Player whose hit set the burn (EnemyManager.damage_source of the ticks).
var burn_source: int = 0
var slow_factor: float = 0.0
var slow_time: float = 0.0
## Wave scaling of contact and projectile damage (StageData.damage_multiplier_at).
var damage_multiplier: float = 1.0
## Boss phase speed factor (BossDirector).
var speed_multiplier: float = 1.0
## While forced_time > 0, the enemy moves at forced_velocity instead of its
## own movement (boss dash, standing still while telegraphing).
var forced_velocity := Vector2.ZERO
var forced_time: float = 0.0
## Charger / kamikaze / spawner state (EnemyManager): countdown, step, aim.
var special_timer: float = 0.0
var special_state: int = 0
var special_dir := Vector2.ZERO
var animator := SpriteAnimator.new()


func reset(p_data: EnemyData, pos: Vector2, hp_multiplier: float, p_elite: bool = false,
		scale_factor: float = 1.0) -> void:
	var look_changed := data != p_data or elite != p_elite
	data = p_data
	elite = p_elite
	position = pos
	max_hp = data.max_hp * hp_multiplier
	hp = max_hp
	radius = data.radius * scale_factor
	knockback = Vector2.ZERO
	separation = Vector2.ZERO
	flash = 0.0
	rotation = 0.0
	burn_dps = 0.0
	burn_time = 0.0
	burn_pending = 0.0
	slow_factor = 0.0
	slow_time = 0.0
	speed_multiplier = 1.0
	forced_velocity = Vector2.ZERO
	forced_time = 0.0
	special_timer = data.spawn_cooldown if data.movement == EnemyData.Movement.SPAWNER else 0.0
	special_state = 0
	special_dir = Vector2.ZERO
	visible = true
	if look_changed:
		animator.reset(data.get_sheet(elite), 0.0)
	_refresh_tint()
	if look_changed:
		queue_redraw()


func is_alive() -> bool:
	return hp > 0.0


func set_flash(value: float) -> void:
	var was_flashing := flash > 0.0
	flash = value
	if was_flashing != (flash > 0.0):
		_refresh_tint()


func apply_burn(dps: float, duration: float) -> void:
	burn_dps = maxf(burn_dps if burn_time > 0.0 else 0.0, dps)
	var was_burning := burn_time > 0.0
	burn_time = maxf(burn_time, duration)
	if not was_burning:
		_refresh_tint()


func end_burn() -> void:
	burn_time = 0.0
	burn_dps = 0.0
	_refresh_tint()


func apply_slow(factor: float, duration: float) -> void:
	slow_factor = maxf(slow_factor if slow_time > 0.0 else 0.0, clampf(factor, 0.0, 0.9))
	var was_slowed := slow_time > 0.0
	slow_time = maxf(slow_time, duration)
	if not was_slowed:
		_refresh_tint()


func end_slow() -> void:
	slow_time = 0.0
	slow_factor = 0.0
	_refresh_tint()


func _refresh_tint() -> void:
	if flash > 0.0:
		self_modulate = FLASH_TINT
	elif burn_time > 0.0:
		self_modulate = BURN_TINT
	elif slow_time > 0.0:
		self_modulate = SLOW_TINT
	else:
		self_modulate = Color.WHITE


func _draw() -> void:
	if data == null:
		return
	var sheet := animator.sheet
	if sheet != null:
		sheet.draw(self, animator.frame, radius * SPRITE_HEIGHT_PER_RADIUS * data.sprite_scale,
			radius * SPRITE_FOOT, animator.facing, data.sprite_tint)
		return
	var texture := data.get_elite_texture(radius / data.radius) if elite else data.get_texture()
	draw_texture(texture, -texture.get_size() * 0.5)
