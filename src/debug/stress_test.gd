extends Node
## Stress test: a real run with 500 enemies and ~1000 projectiles.
## Run in the editor (F6) or: Godot.exe --path . res://src/debug/stress_test.tscn -- --duration=30
## Prints FPS and frame-time statistics, then quits when a duration is given.
## --endless=N: the real stage at Danger 1 instead, starting directly at endless wave N
## (N = 1: a whole run that goes on into endless mode; object counts logged per wave).
## --coop: two players, every weapon at max level for both (worst case of local coop).
## --speed=X: Engine.time_scale, to reach late waves faster (--duration is in game seconds).

const RUN_SCENE := preload("res://src/run/run.tscn")
const STRESS_CONFIG := preload("res://src/debug/stress/stress_run.tres")
const WARMUP := 5.0

## One weapon per behavior and projectile style (one melee, beam, orb, bolt, rocket, bounce).
const REFERENCE_WEAPONS: Array[StringName] = [&"pulse", &"katana", &"laser_pistol", &"shuriken", &"smg", &"bazooka"]

var _run: Run
var _time: float = 0.0
var _duration: float = 0.0
var _samples_fps: PackedFloat32Array = []
var _samples_physics: PackedFloat32Array = []
var _samples_process: PackedFloat32Array = []
var _samples_draw_calls: PackedFloat32Array = []
var _max_enemies: int = 0
var _max_projectiles: int = 0
var _sample_timer: float = 0.0
var _endless_wave: int = 0
var _coop: bool = false
var _max_enemy_shots: int = 0
var _max_vfx: int = 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--duration="):
			_duration = arg.trim_prefix("--duration=").to_float()
		elif arg == "--coop":
			_coop = true
		elif arg.begins_with("--speed="):
			Engine.time_scale = arg.trim_prefix("--speed=").to_float()
		elif arg.begins_with("--endless="):
			_endless_wave = arg.trim_prefix("--endless=").to_int()
	_run = RUN_SCENE.instantiate()
	if _endless_wave > 0:
		_run.setup = RunSetup.new()
		_run.setup.difficulty = ContentDB.get_def(&"difficulties", &"danger_1")
	else:
		_run.config = STRESS_CONFIG
	_run.seed_override = 1
	_run.player_invincible = true
	_run.auto_choose_upgrades = true
	if _coop:
		_run.player_count = 2
	_run.bot_input = func() -> Vector2: return Vector2.from_angle(_time * 0.5)
	add_child(_run)
	# The six reference weapons at max level on top of the stress weapon: worst case
	# for effects, kept fixed so measurements stay comparable as weapons are added.
	for rp in _run.players:
		for id in REFERENCE_WEAPONS:
			var weapon: WeaponData = ContentDB.get_def(&"weapons", id)
			rp.player.weapons.add_weapon(weapon, weapon.max_level())
	if _endless_wave > 0:
		_run.stage.endless = true
		_run.waves.start_wave(_endless_wave)
		_run.waves.wave_ended.connect(_log_objects)


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
		_samples_draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		_max_enemies = maxi(_max_enemies, _run.enemies.active_count())
		_max_projectiles = maxi(_max_projectiles, _run.projectiles.active_count())
		_max_enemy_shots = maxi(_max_enemy_shots, _run.enemy_projectiles.active_count())
		_max_vfx = maxi(_max_vfx, _run.vfx.active_count())
	if _duration > 0.0 and _time >= WARMUP + _duration:
		_report()
		get_tree().quit()


## Leak hunt: object and node counts after each wave (between-wave cleanup done).
func _log_objects(wave: int) -> void:
	print("[objects] wave %d | objects %d | nodes %d | orphans %d | resources %d | fps %d" % [
		wave, Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), Engine.get_frames_per_second()])


func _report() -> void:
	print("=== STRESS TEST (%.0f s) ===" % _duration)
	print("enemies max %d | projectiles max %d | enemy shots max %d | gems %d | vfx max %d" % [
		_max_enemies, _max_projectiles, _max_enemy_shots, _run.pickups.active_count(), _max_vfx])
	if _endless_wave > 0:
		print("endless: started at wave %d, now wave %d" % [_endless_wave, _run.waves.wave])
	print("FPS        avg %.1f | min %.1f" % [_avg(_samples_fps), _min(_samples_fps)])
	print("physics ms avg %.2f | max %.2f" % [_avg(_samples_physics), _max(_samples_physics)])
	print("process ms avg %.2f | max %.2f" % [_avg(_samples_process), _max(_samples_process)])
	print("draw calls avg %.0f | max %.0f" % [_avg(_samples_draw_calls), _max(_samples_draw_calls)])


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
