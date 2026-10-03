class_name GameCamera
extends Camera2D
## Player camera with trauma-based screen shake (shake = trauma^2, decays over time).
## The shake follows smooth noise over time: a new random offset every rendered
## frame (hundreds per second) made the whole picture look blurred.

const MAX_OFFSET := 12.0
const DECAY := 1.6
## Shake oscillations per second.
const FREQUENCY := 10.0
## Explosions alone never push the trauma above this (a bazooka build fires
## them constantly); hits on the player can go higher.
const EXPLOSION_CAP := 0.45

## Can be turned off (accessibility, future settings menu).
var shake_enabled: bool = true

var _trauma: float = 0.0
var _time: float = 0.0
## Visual only: never use the run RNG here, it would change gameplay rolls.
var _noise := FastNoiseLite.new()


func _init() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 10.0
	# Same rate as the player's movement (physics ticks): updated every rendered
	# frame, the camera made the player stutter against it, seen as motion blur.
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	_noise.seed = randi()


## Adds shake, without raising it above `cap` (explosions use EXPLOSION_CAP).
func add_trauma(amount: float, cap: float = 1.0) -> void:
	if shake_enabled and _trauma < cap:
		_trauma = minf(_trauma + amount, cap)


func trauma() -> float:
	return _trauma


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO
		return
	_trauma = maxf(_trauma - DECAY * delta, 0.0)
	_time += delta * FREQUENCY
	var strength := _trauma * _trauma * MAX_OFFSET
	offset = Vector2(_noise.get_noise_2d(_time, 0.0), _noise.get_noise_2d(0.0, _time + 100.0)) * strength
