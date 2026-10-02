class_name RunState
extends RefCounted
## Plain data of the current run. Every random roll of the run uses `rng`
## so that a run can be replayed from its seed.

var run_seed: int
var rng := RandomNumberGenerator.new()
var elapsed: float = 0.0
var kills: int = 0
var is_over: bool = false


func _init(p_seed: int) -> void:
	run_seed = p_seed
	rng.seed = p_seed
