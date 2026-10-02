extends Node
## Stress test: a real run with 500 enemies and ~1000 projectiles.
## Run in the editor (F6) or: Godot.exe --path . res://src/debug/stress_test.tscn -- --duration=30
## Prints FPS and frame-time statistics, then quits when a duration is given.

const RUN_SCENE := preload("res://src/run/run.tscn")
const STRESS_CONFIG := preload("res://src/debug/stress/stress_run.tres")
const WARMUP := 5.0

var _run: Run
var _time: float = 0.0
var _duration: float = 0.0
var _samples_fps: PackedFloat32Array = []
var _samples_physics: PackedFloat32Array = []
var _samples_process: PackedFloat32Array = []
var _max_enemies: int = 0
var _max_projectiles: int = 0
var _sample_timer: float = 0.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--duration="):
			_duration = arg.trim_prefix("--duration=").to_float()
	_run = RUN_SCENE.instantiate()
	_run.config = STRESS_CONFIG
	_run.seed_override = 1
	_run.player_invincible = true
	_run.auto_choose_upgrades = true
	_run.bot_input = func() -> Vector2: return Vector2.from_angle(_time * 0.5)
	add_child(_run)
	# Every real weapon at max level on top of the stress weapon: worst case for effects.
	for def in ContentDB.get_all(&"weapons"):
		var weapon := def as WeaponData
		_run.player.weapons.add_weapon(weapon, weapon.max_level())


func _process(delta: float) -> void:
	_time += delta
	if _time < WARMUP:
		return
	_sample_timer -= delta
	if _sample_timer <= 0.0:
		_sample_timer = 0.5
		_samples_fps.append(Engine.get_frames_per_second())
		_samples_physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		_samples_process.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		_max_enemies = maxi(_max_enemies, _run.enemies.active_count())
		_max_projectiles = maxi(_max_projectiles, _run.projectiles.active_count())
	if _duration > 0.0 and _time >= WARMUP + _duration:
		_report()
		get_tree().quit()


func _report() -> void:
	print("=== STRESS TEST (%.0f s) ===" % _duration)
	print("enemies max %d | projectiles max %d | gems %d | vfx %d" % [
		_max_enemies, _max_projectiles, _run.pickups.active_count(), _run.vfx.active_count()])
	print("FPS        avg %.1f | min %.1f" % [_avg(_samples_fps), _min(_samples_fps)])
	print("physics ms avg %.2f | max %.2f" % [_avg(_samples_physics), _max(_samples_physics)])
	print("process ms avg %.2f | max %.2f" % [_avg(_samples_process), _max(_samples_process)])


func _avg(values: PackedFloat32Array) -> float:
	var total := 0.0
	for v in values:
		total += v
	return total / maxf(values.size(), 1.0)


func _min(values: PackedFloat32Array) -> float:
	var result := INF
	for v in values:
		result = minf(result, v)
	return result


func _max(values: PackedFloat32Array) -> float:
	var result := 0.0
	for v in values:
		result = maxf(result, v)
	return result
