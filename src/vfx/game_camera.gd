class_name GameCamera
extends Camera2D
## Player camera with trauma-based screen shake (shake = trauma^2, decays over time).

const MAX_OFFSET := 18.0
const DECAY := 1.6

## Can be turned off (accessibility, future settings menu).
var shake_enabled: bool = true

var _trauma: float = 0.0
## Visual only: never use the run RNG here, it would change gameplay rolls.
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 10.0
	# Same rate as the player's movement (physics ticks): updated every rendered
	# frame, the camera made the player stutter against it, seen as motion blur.
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func add_trauma(amount: float) -> void:
	if shake_enabled:
		_trauma = minf(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO
		return
	_trauma = maxf(_trauma - DECAY * delta, 0.0)
	var strength := _trauma * _trauma * MAX_OFFSET
	offset = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * strength
