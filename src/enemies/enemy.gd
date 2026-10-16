class_name Enemy
extends Node2D
## Passive enemy: data, runtime state and placeholder visual. Moved, damaged and
## ticked by EnemyManager (no _process here, see ADR 0002).
## Visual: animated sprite sheet (frame advanced by EnemyManager, redrawn only
## when the frame or facing changes), or the baked neon placeholder (EnemyArt)
## when the type has no sprite. Hit flash and statuses only change `self_modulate`.

## Hit flash: 0.04 s of pure white. The tint is far above 1 so every lit pixel of the sprite saturates to white (only its
## dark outline stays dark); a shader per enemy would break the batching of 650 sprites.
const FLASH_TIME := 0.04
const FLASH_TINT := Color(8.0, 8.0, 8.0)
const BURN_TINT := Color(1.8, 1.0, 0.55)
const SLOW_TINT := Color(0.55, 0.9, 1.8)
const RAGE_TINT := Color(1.5, 0.6, 0.55)
const POISON_TINT := Color(0.75, 1.5, 0.6)
## Sprite height in px per px of collision radius.
const SPRITE_HEIGHT_PER_RADIUS := 5.0
## An enemy's position (hitbox center, where hits are measured) is at the middle of its body:
## the feet sit this share of the sprite's height below it. It used to be near the feet, so a
## slash that visibly cut through an enemy's torso missed it (playtest 2026-10-09).
const HIP_SHARE := 0.48

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
## Poison: stacked hits, damage per second of each stack, time left, damage not yet shown, who and which weapon applied it.
var poison_stacks: int = 0
var poison_dps: float = 0.0
var poison_time: float = 0.0
var poison_pending: float = 0.0
var poison_source: int = 0
var poison_weapon: StringName = &""
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
## A boss past the clock (BossDirector): redder, faster, harder.
var enraged: bool = false
## Attack animation (EnemyData.attack_sheet): time left, total length and the frame shown.
var attack_left: float = 0.0
var attack_length: float = 1.0
var attack_frame: int = 0
## Share (0..1) of the next frame cross-faded over the current one (smooth hold poses).
var attack_blend: float = 0.0


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
	poison_stacks = 0
	poison_dps = 0.0
	poison_time = 0.0
	poison_pending = 0.0
	speed_multiplier = 1.0
	forced_velocity = Vector2.ZERO
	forced_time = 0.0
	special_timer = data.spawn_cooldown if data.movement == EnemyData.Movement.SPAWNER else 0.0
	special_state = 0
	special_dir = Vector2.ZERO
	attack_left = 0.0
	enraged = false
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


## One more stack of poison (up to `max_stacks`); every hit refreshes its duration.
func apply_poison(dps_per_stack: float, duration: float, max_stacks: int) -> void:
	var was_poisoned := poison_time > 0.0
	poison_stacks = mini(poison_stacks + 1, maxi(max_stacks, 1)) if was_poisoned else 1
	poison_dps = maxf(poison_dps if was_poisoned else 0.0, dps_per_stack)
	poison_time = maxf(poison_time, duration)
	if not was_poisoned:
		_refresh_tint()


func end_poison() -> void:
	poison_stacks = 0
	poison_dps = 0.0
	poison_time = 0.0
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
	elif poison_time > 0.0:
		self_modulate = POISON_TINT
	elif slow_time > 0.0:
		self_modulate = SLOW_TINT
	elif enraged:
		self_modulate = RAGE_TINT
	else:
		self_modulate = Color.WHITE


## Height of the drawn sprite in px.
func sprite_height() -> float:
	return radius * SPRITE_HEIGHT_PER_RADIUS * data.sprite_scale


## Distance from the enemy's position (its body center) down to its feet.
func foot_offset() -> float:
	return sprite_height() * HIP_SHARE


## Plays the attack frames over `length` seconds (no sheet: nothing happens).
func start_attack(length: float) -> void:
	if data.attack_sheet == null:
		return
	attack_length = maxf(length, 0.1)
	attack_left = attack_length
	attack_frame = 0
	attack_blend = 0.0
	queue_redraw()


## Advances the attack animation; true when the frame changed or it ended (redraw needed).
func tick_attack(delta: float) -> bool:
	attack_left = maxf(attack_left - delta, 0.0)
	var frames := maxi(data.attack_sheet.animations.get(&"attack", Vector3i(0, 1, 1)).y, 1)
	var total := 0.0
	for i in frames:
		total += data.attack_frame_weight(i)
	# Position in the animation, in weight units, then the frame it falls in and how far through it.
	var at := (1.0 - attack_left / attack_length) * total
	var frame := frames - 1
	var local := 0.0
	var passed := 0.0
	for i in frames:
		var weight := data.attack_frame_weight(i)
		if at < passed + weight:
			frame = i
			local = (at - passed) / maxf(weight, 0.001)
			break
		passed += weight
	var blend := local if frame < frames - 1 and attack_left > 0.0 else 0.0
	attack_frame = frame
	attack_blend = blend
	return true


func _draw() -> void:
	if data == null:
		return
	if attack_left > 0.0 and data.attack_sheet != null:
		var height := sprite_height() * data.attack_scale
		data.attack_sheet.draw(self, attack_frame, height, foot_offset(), animator.facing, data.sprite_tint)
		if attack_blend > 0.02:
			var faded := Color(data.sprite_tint, data.sprite_tint.a * attack_blend)
			data.attack_sheet.draw(self, attack_frame + 1, height, foot_offset(), animator.facing, faded)
		return
	var sheet := animator.sheet
	if sheet != null:
		sheet.draw(self, animator.frame, sprite_height(), foot_offset(), animator.facing, data.sprite_tint)
		return
	var texture := data.get_elite_texture(radius / data.radius) if elite else data.get_texture()
	draw_texture(texture, -texture.get_size() * 0.5)
