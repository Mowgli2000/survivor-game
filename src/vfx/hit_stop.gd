class_name HitStop
extends Node
## Hit-stop: the game almost freezes for a few tens of milliseconds on a heavy kill (an elite, a mini-boss,
## the final boss), to give the blow some weight. Uses Engine.time_scale, restored by a real-time timer.
## Whoever else sets the time scale (the boss death slow-motion) goes through set_base_scale().

## Freeze lengths, in real seconds.
const ELITE := 0.04
const MINI_BOSS := 0.06
const BOSS_DEATH := 0.08
## Time scale while frozen (not 0: timers and tweens keep a valid delta).
const FROZEN_SCALE := 0.02
## Two freezes are never closer than this, in real seconds (a horde of elites must not stutter).
const MIN_GAP := 0.6

## Off for players who reduce flashes (accessibility).
var enabled: bool = true

var _frozen: bool = false
var _base_scale: float = 1.0
var _last_start_msec: int = -100000


## Freezes for `duration` real seconds. `force` skips the minimum gap (a final boss's death).
## Returns true when a freeze started.
func request(duration: float, force: bool = false) -> bool:
	if not enabled or _frozen or duration <= 0.0:
		return false
	var now := Time.get_ticks_msec()
	if not force and now - _last_start_msec < int(MIN_GAP * 1000.0):
		return false
	_last_start_msec = now
	_frozen = true
	_base_scale = Engine.time_scale
	Engine.time_scale = FROZEN_SCALE
	get_tree().create_timer(duration, true, false, true).timeout.connect(_end)
	return true


## The time scale the game runs at outside a freeze (slow-motion). During a freeze it applies at the end.
func set_base_scale(scale: float) -> void:
	if _frozen:
		_base_scale = scale
	else:
		Engine.time_scale = scale


func is_frozen() -> bool:
	return _frozen


func _end() -> void:
	if not _frozen:
		return
	_frozen = false
	Engine.time_scale = _base_scale


func _exit_tree() -> void:
	if _frozen:
		_frozen = false
		Engine.time_scale = _base_scale
