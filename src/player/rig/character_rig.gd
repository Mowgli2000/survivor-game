class_name CharacterRig
extends Node2D
## Puppet of a playable character (ADR 0020): one Sprite2D per RigData piece,
## all direct children in drawing order, posed by code every frame (forward
## kinematics: each piece turns around its joint, carried by its parent).
## Animations are procedural, like PlayerMotion: idle breathing, walk cycle
## (stride with knees, arm swing, bob, ponytail spring), hit flinch, death fall. One or two players only.

## Walk cycles per second at full speed.
const WALK_RATE := 2.4
## How fast idle and walk blend into each other (per second).
const BLEND_SPEED := 8.0
## Leg and arm swing at full walk, in radians.
const LEG_SWING := 0.42
## Knee bend of the leg swinging back, in radians.
const KNEE_BEND := 0.55
## Forward lean of the upper body while walking, in radians.
const WALK_LEAN := 0.07
## Ponytail spring (stiffness, damping) and how far it lifts behind at full walk.
const HAIR_STIFFNESS := 70.0
const HAIR_DAMPING := 7.0
const HAIR_LIFT := 0.3
const ARM_SWING := 0.4
## Extra elbow bend when the arm swings back.
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
## Ponytail angle and its spring velocity.
var _hair: float = 0.0
var _hair_velocity: float = 0.0


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
	# Ponytail: lifts behind while walking, bounces with the steps, sways at rest.
	var hair_target := HAIR_LIFT * _walk_blend + sin(_walk_phase * 2.0) * 0.1 * _walk_blend 		+ sin(_time * 1.6) * 0.05 * (1.0 - _walk_blend) - _hurt * 0.3
	_hair_velocity += ((hair_target - _hair) * HAIR_STIFFNESS - _hair_velocity * HAIR_DAMPING) * delta
	_hair += _hair_velocity * delta
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
	# Three-quarter view facing right: a positive angle turns clockwise, so a
	# negative one swings a hanging limb forward (toward +x).
	var stride := sin(_walk_phase) * _walk_blend
	var breath := sin(_time * 2.2) * (1.0 - _walk_blend)
	_turn(&"leg_front", -stride * LEG_SWING)
	_turn(&"leg_back", stride * LEG_SWING)
	# The knee bends while its leg swings back (foot lifted behind).
	_turn(&"shin_front", maxf(stride, 0.0) * KNEE_BEND)
	_turn(&"shin_back", maxf(-stride, 0.0) * KNEE_BEND)
	# Arms swing against the legs; the hit throws them out.
	# The arms already hang out from the body: they swing back half as far.
	_turn(&"arm_front", _arm_swing(stride) + breath * 0.04 - _hurt * 0.6)
	_turn(&"arm_back", -_arm_swing(-stride) - breath * 0.04 + _hurt * 0.5)
	_turn(&"hand_front", -maxf(-stride, 0.0) * ELBOW_SWING - _hurt * 0.3)
	_turn(&"hand_back", -maxf(stride, 0.0) * ELBOW_SWING)
	_turn(&"torso", WALK_LEAN * _walk_blend + breath * 0.01 - _hurt * 0.12)
	_turn(&"head", sin(_time * 1.3) * 0.03 * (1.0 - _walk_blend) - WALK_LEAN * 0.5 * _walk_blend + _hurt * 0.15)
	_turn(&"skirt", -sin(_walk_phase * 2.0) * 0.05 * _walk_blend - WALK_LEAN * 0.6 * _walk_blend)
	_turn(&"ponytail", _hair)
	# Highest when the legs pass each other, lowest when they are apart.
	_bob = -(1.0 - absf(sin(_walk_phase))) * WALK_BOB * _walk_blend + breath * BREATH
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
			local = body * Transform2D(_angles[i], rig.joints[i])
		else:
			# Rest offset from the parent's joint, carried by the parent's pose.
			local = placed[parent] * Transform2D(_angles[i], rig.joints[i] - rig.joints[parent])
		placed[i] = local
		_sprites[i].transform = local


## Swing of an arm: full forward (negative), half backward (positive).
func _arm_swing(stride: float) -> float:
	return stride * ARM_SWING * (0.45 if stride > 0.0 else 1.0)


func _turn(piece: StringName, angle: float) -> void:
	var i := rig.index_of(piece)
	if i >= 0:
		_angles[i] = angle
