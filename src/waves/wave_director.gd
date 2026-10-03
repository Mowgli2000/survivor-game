class_name WaveDirector
extends Node
## Owns the wave clock and state only: no spawning, no UI.
## A wave ends when its timer reaches 0; the next one starts only when
## start_wave() is called (by Run, after the between-waves screen).

signal wave_started(wave: int)
signal wave_ended(wave: int)
## Emitted right after wave_ended when the last wave is over.
signal run_won

## Current wave, 1-based (0 before the first wave).
var wave: int = 0
var time_left: float = 0.0
var in_wave: bool = false

var _stage: StageData


func setup(stage: StageData) -> void:
	_stage = stage


func _ready() -> void:
	# Before SpawnDirector (-20) so spawning sees the up-to-date wave state.
	process_physics_priority = -30


func start_wave(p_wave: int) -> void:
	wave = p_wave
	time_left = _stage.duration_at(wave)
	in_wave = true
	wave_started.emit(wave)


## Seconds since the start of the current wave.
func wave_elapsed() -> float:
	return _stage.duration_at(wave) - time_left


## Ends the current wave on the next physics frame, through the normal path
## (wave_ended, then run_won on the last wave). Used when every boss is dead.
func finish_wave() -> void:
	if in_wave:
		time_left = 0.0


func wave_count() -> int:
	return _stage.wave_count


## Never true in endless mode: the run goes on until the player dies.
func is_last_wave() -> bool:
	return not _stage.endless and wave >= _stage.wave_count


func _physics_process(delta: float) -> void:
	if not in_wave:
		return
	time_left -= delta
	if time_left > 0.0:
		return
	time_left = 0.0
	in_wave = false
	# Keep the ended wave: a listener may already start the next one during the emit.
	var ended := wave
	wave_ended.emit(ended)
	if ended >= _stage.wave_count and not _stage.endless:
		run_won.emit()
