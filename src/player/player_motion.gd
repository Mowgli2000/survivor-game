class_name PlayerMotion
extends RefCounted
## Procedural "juice" of the player sprite, on top of the baked idle/walk frames:
## lean toward the movement (spring, overshoots when starting/stopping), squash
## when hit + white flash, coat sway and step dust. Pure state updated once per
## frame by Player, which draws it.

## Max lean, in radians, at full speed.
const MAX_LEAN := 0.16
## Spring of the lean (stiffness, damping): a little overshoot.
const LEAN_STIFFNESS := 180.0
const LEAN_DAMPING := 14.0
## Hit reaction length (squash + flash), in seconds.
const HURT_TIME := 0.18
## Dust puffs: one every STEP_INTERVAL s while moving, each lives DUST_LIFE s.
const STEP_INTERVAL := 0.16
const DUST_LIFE := 0.4
const MAX_DUST := 8
## Below this speed ratio the player counts as standing still.
const MOVING_RATIO := 0.15

## Current lean angle (radians, positive = leaning right).
var lean: float = 0.0
## 1 = facing right (art default), -1 = mirrored. Turns instantly.
var facing: float = 1.0
## 0..1: how fast the player moves (coat sway).
var speed_ratio: float = 0.0
## 0..1: white flash of the hit reaction.
var flash: float = 0.0
## Global positions and ages of the dust puffs.
var dust_positions := PackedVector2Array()
var dust_ages := PackedFloat32Array()

var _lean_velocity: float = 0.0
var _hurt: float = 0.0
var _step_timer: float = 0.0


func update(delta: float, position: Vector2, velocity: Vector2, max_speed: float) -> void:
	speed_ratio = clampf(velocity.length() / maxf(max_speed, 1.0), 0.0, 1.0)
	var moving := speed_ratio > MOVING_RATIO

	var target_lean := clampf(velocity.x / maxf(max_speed, 1.0), -1.0, 1.0) * MAX_LEAN
	_lean_velocity += ((target_lean - lean) * LEAN_STIFFNESS - _lean_velocity * LEAN_DAMPING) * delta
	lean += _lean_velocity * delta

	if absf(velocity.x) > SpriteAnimator.FACING_DEADZONE:
		facing = signf(velocity.x)

	_hurt = maxf(_hurt - delta, 0.0)
	flash = _hurt / HURT_TIME

	_update_dust(delta, position, moving)


## Hit reaction: squash + white flash.
func hurt() -> void:
	_hurt = HURT_TIME


## Scale of the sprite around its feet: facing, then the hit squash.
func body_scale() -> Vector2:
	var k := _hurt / HURT_TIME
	return Vector2(facing * (1.0 + 0.18 * k), 1.0 - 0.15 * k)


func _update_dust(delta: float, position: Vector2, moving: bool) -> void:
	for i in range(dust_ages.size() - 1, -1, -1):
		dust_ages[i] += delta
		if dust_ages[i] >= DUST_LIFE:
			dust_ages.remove_at(i)
			dust_positions.remove_at(i)
	if not moving:
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = STEP_INTERVAL
		if dust_ages.size() >= MAX_DUST:
			dust_ages.remove_at(0)
			dust_positions.remove_at(0)
		dust_positions.append(position)
		dust_ages.append(0.0)

