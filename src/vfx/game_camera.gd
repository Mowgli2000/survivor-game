class_name GameCamera
extends Camera2D
## Run camera: follows the players' center (ADR 0017; coop: zooms out as far as needed
## to keep both players in view, they can be at opposite ends of the arena) with trauma-based screen shake (shake = trauma^2, decays over time).
## The shake follows smooth noise over time: a new random offset every rendered
## frame (hundreds per second) made the whole picture look blurred.

const MAX_OFFSET := 12.0
const DECAY := 1.6
## Shake oscillations per second.
const FREQUENCY := 10.0
## Explosions alone never push the trauma above this (a bazooka build fires
## them constantly); hits on the player can go higher.
const EXPLOSION_CAP := 0.45

## Coop: empty space kept around the two players when the zoom fits them, in px.
const FIT_MARGIN := 560.0
## Coop: the zoom never goes below this (the whole arena stays in view at about 0.45).
const MIN_ZOOM := 0.4
const ZOOM_SPEED := 3.0

## Can be turned off (accessibility, future settings menu).
var shake_enabled: bool = true
## Zoom with the players together (RunConfig.camera_zoom).
var base_zoom: float = 1.0
## Followed group; null = the camera stays where its parent puts it.
var party: Party

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


## Starts following `p_party`, centered at once (no smoothing from the origin).
func follow(p_party: Party, p_base_zoom: float) -> void:
	party = p_party
	base_zoom = p_base_zoom
	zoom = Vector2.ONE * base_zoom
	global_position = party.center()
	reset_smoothing()


func _physics_process(delta: float) -> void:
	if party == null:
		return
	global_position = party.center()
	var target := base_zoom
	if party.size() > 1:
		target = fit_zoom(party, get_viewport_rect().size, base_zoom)
	if not is_equal_approx(zoom.x, target):
		zoom = Vector2.ONE * move_toward(zoom.x, target, ZOOM_SPEED * base_zoom * delta)


## Zoom that keeps every living player in view with FIT_MARGIN around them, never above
## `base` (the players together) nor below MIN_ZOOM. `view`: the screen size in px.
static func fit_zoom(p_party: Party, view: Vector2, base: float) -> float:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for player in p_party.members:
		if player.is_dead:
			continue
		low = low.min(player.global_position)
		high = high.max(player.global_position)
	if low.x == INF:
		return base
	var box := high - low + Vector2(FIT_MARGIN, FIT_MARGIN)
	return clampf(minf(view.x / box.x, view.y / box.y), MIN_ZOOM, base)


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
