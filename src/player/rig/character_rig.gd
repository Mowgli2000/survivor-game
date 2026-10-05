class_name CharacterRig
extends Node2D
## Puppet of a playable character (ADR 0020): one Sprite2D per RigData piece,
## all direct children in drawing order, posed by code every frame (forward
## kinematics: each piece turns around its joint, carried by its parent).
## Animations are procedural, like PlayerMotion: idle breathing, walk cycle
## (legs, arm swing, bob), hit flinch, death fall. One or two players only.

## Walk cycles per second at full speed.
const WALK_RATE := 2.4
## How fast idle and walk blend into each other (per second).
const BLEND_SPEED := 8.0
## Leg and arm swing at full walk, in radians.
const LEG_SWING := 0.12
const ARM_SWING := 0.28
## Leg lift at each step, in texture px.
const LEG_LIFT := 9.0
## Elbows stay a little bent at rest; more when the arm swings forward.
const ELBOW_REST := 0.12
const ELBOW_SWING := 0.3
## Body bob while walking, and breathing at rest, in texture px.
const WALK_BOB := 7.0
const BREATH := 1.6
## Death fall length, in seconds.
const DEATH_TIME := 0.45
const FLASH_SHADER := preload("res://src/player/rig/rig_flash.gdshader")

var rig: RigData
## 0..1: white hit flash (PlayerMotion.flash).
var flash: float = 0.0

var _sprites: Array[Sprite2D] = []
var _parents := PackedInt32Array()
## Piece indices with every parent before its children (posing order).
var _order := PackedInt32Array()
## Rotation of each piece around its joint this frame (radians).
var _angles := PackedFloat32Array()
var _walk_phase: float = 0.0
var _walk_blend: float = 0.0
var _time: float = 0.0
var _hurt: float = 0.0
var _death: float = -1.0
var _bob: float = 0.0


func setup(p_rig: RigData) -> void:
	rig = p_rig
	var shader_material := ShaderMaterial.new()
	shader_material.shader = FLASH_SHADER
	material = shader_material
	_parents.resize(rig.names.size())
	_angles.resize(rig.names.size())
	for i in rig.names.size():
		_parents[i] = rig.index_of(StringName(rig.parents[i]))
		var sprite := Sprite2D.new()
		sprite.texture = rig.texture
		sprite.region_enabled = true
		sprite.region_rect = rig.regions[i]
		sprite.centered = false
		sprite.offset = -rig.pivots[i]
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.use_parent_material = true
		add_child(sprite)
		_sprites.append(sprite)
	var placed := {}
	while _order.size() < _parents.size():
		for i in _parents.size():
			if not placed.has(i) and (_parents[i] < 0 or placed.has(_parents[i])):
				placed[i] = true
				_order.append(i)
	_pose()


## Advances the animation. `speed_ratio` 0..1 (PlayerMotion), `hurt` 0..1 (hit reaction).
func animate(delta: float, speed_ratio: float, hurt: float) -> void:
	_time += delta
	_hurt = hurt
	if _death >= 0.0:
		_death = minf(_death + delta / DEATH_TIME, 1.0)
	else:
		var moving := 1.0 if speed_ratio > PlayerMotion.MOVING_RATIO else 0.0
		_walk_blend = move_toward(_walk_blend, moving, BLEND_SPEED * delta)
		_walk_phase = fmod(_walk_phase + delta * WALK_RATE * TAU * maxf(speed_ratio, 0.5) * _walk_blend, TAU)
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter(&"flash", flash)
	_pose()


## Falls over (the player died); revive() stands it back up.
func die() -> void:
	if _death < 0.0:
		_death = 0.0


func revive() -> void:
	_death = -1.0


func is_dead() -> bool:
	return _death >= 0.0


## Current angle of `piece` (tests, previews).
func angle_of(piece: StringName) -> float:
	var i := rig.index_of(piece)
	return _angles[i] if i >= 0 else 0.0


func _pose() -> void:
	_angles.fill(0.0)
	var walk := sin(_walk_phase) * _walk_blend
	var breath := sin(_time * 2.2) * (1.0 - _walk_blend)
	# Front view: steps read as legs lifting in turn, with a small swing.
	_turn(&"leg_l", walk * LEG_SWING)
	_turn(&"leg_r", walk * LEG_SWING)
	# Front view: both arms sway the same way (one in front of the body, one
	# out), against the lifted leg; the hit throws them out.
	var flinch := _hurt * 0.55
	_turn(&"arm_l", -walk * ARM_SWING + breath * 0.04 + flinch)
	_turn(&"arm_r", -walk * ARM_SWING - breath * 0.04 - flinch)
	_turn(&"hand_l", -ELBOW_REST - maxf(walk, 0.0) * ELBOW_SWING)
	_turn(&"hand_r", ELBOW_REST - maxf(-walk, 0.0) * ELBOW_SWING)
	_turn(&"torso", sin(_walk_phase * 2.0) * 0.03 * _walk_blend - _hurt * 0.08)
	_turn(&"head", sin(_time * 1.3) * 0.03 * (1.0 - _walk_blend) - sin(_walk_phase * 2.0) * 0.04 * _walk_blend + _hurt * 0.12)
	_turn(&"skirt", -sin(_walk_phase * 2.0) * 0.06 * _walk_blend)
	# Hops twice per cycle (each step), breathes at rest.
	_bob = -absf(sin(_walk_phase)) * WALK_BOB * _walk_blend + breath * BREATH
	var body := Transform2D(0.0, Vector2(0.0, _bob))
	if _death >= 0.0:
		# Tips over backward around the feet, then lies flat.
		var t := ease(_death, 0.4)
		body = Transform2D(-t * PI * 0.5, Vector2(0.0, 0.0))
	var placed: Array[Transform2D] = []
	placed.resize(_sprites.size())
	for i in _order:
		var parent := _parents[i]
		var local: Transform2D
		if parent < 0:
			local = body * Transform2D(_angles[i], rig.joints[i] + Vector2(0.0, -_lift(i)))
		else:
			# Rest offset from the parent's joint, carried by the parent's pose.
			local = placed[parent] * Transform2D(_angles[i], rig.joints[i] - rig.joints[parent])
		placed[i] = local
		_sprites[i].transform = local


## Legs lift in turn while walking (texture px).
func _lift(i: int) -> float:
	var side := 1.0 if rig.names[i] == "leg_l" else (-1.0 if rig.names[i] == "leg_r" else 0.0)
	return maxf(sin(_walk_phase) * side, 0.0) * LEG_LIFT * _walk_blend


func _turn(piece: StringName, angle: float) -> void:
	var i := rig.index_of(piece)
	if i >= 0:
		_angles[i] = angle
