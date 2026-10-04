extends Node
## Fast balance simulator runner (ADR 0019). One process, thousands of runs:
##   matrix:    Godot.exe --headless --path . res://src/debug/balance/balance_fast.tscn --
##                --out=<dir> [--seeds=20] [--policies=dps,family,tank,economy,random] [--seals=0-5]
##              -> <dir>/runs.jsonl (+ python tools/balance/report.py <dir>)
##   calibrate: ... -- --calibrate=<dir with runs/ of real headless runs>
##              -> tools/balance/calibration.json (k_kill, k_area, f_hit, p_exp)
## WaveSim reads its coefficients from tools/balance/calibration.json.

const CALIBRATION := "res://tools/balance/calibration.json"
const GRID := {
	"k_kill": [0.3, 0.5, 0.75, 1.0, 1.5, 2.0],
	"k_area": [0.3, 0.6, 1.0],
	"f_hit": [0.25, 0.5, 1.0, 2.0, 4.0],
	"p_exp": [1.0, 1.5, 2.0],
}
const CALIBRATION_SEEDS := 3

var _config: RunConfig


func _ready() -> void:
	_config = ContentDB.get_def(&"runs", Run.DEFAULT_CONFIG_ID)
	if _config.shop == null:
		_config.shop = ContentDB.get_def(&"shop", &"default")
	var args := {"out": "user://balance_fast", "seeds": "20", "policies": "dps,family,tank,economy,random",
		"seals": "0-5", "calibrate": ""}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			args[parts[0]] = parts[1]
	if args.get("compare", "") != "":
		_compare(args.compare)
	elif args.calibrate != "":
		_calibrate(args.calibrate)
	else:
		_matrix(args)
	get_tree().quit()


static func load_calibration() -> Dictionary:
	if not FileAccess.file_exists(CALIBRATION):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CALIBRATION))
	return data if data is Dictionary else {}


func _new_sim(character: CharacterData, weapon: WeaponData, seal: int, policy: String, seed: int,
		params: Dictionary) -> WaveSim:
	var sim := WaveSim.new()
	for key in params:
		if key in GRID:
			sim.set(key, float(params[key]))
	var difficulty: DifficultyData = ContentDB.get_def(&"difficulties", StringName("danger_%d" % seal))
	sim.setup(character, weapon, difficulty, policy, seed, _config)
	return sim


func _matrix(args: Dictionary) -> void:
	var params := load_calibration()
	# --params=k_kill:0.5,f_hit:1 overrides the calibration (manual tuning).
	if args.get("params", "") != "":
		for pair in String(args.params).split(","):
			var kv := pair.split(":")
			params[kv[0]] = float(kv[1])
	DirAccess.make_dir_recursive_absolute(args.out)
	var file := FileAccess.open(String(args.out).path_join("runs.jsonl"), FileAccess.WRITE)
	var seals := _range(args.seals)
	var started := Time.get_ticks_msec()
	var count := 0
	for def in ContentDB.get_all(&"characters"):
		var character := def as CharacterData
		if args.get("characters", "") != "" and not String(args.characters).split(",").has(String(character.id)):
			continue
		for weapon in character.starting_weapons:
			for seal in seals:
				for policy in String(args.policies).split(","):
					for seed in range(1, int(args.seeds) + 1):
						var report := _new_sim(character, weapon, seal, policy, seed, params).play()
						report["weapon"] = String(weapon.id)
						report["seal"] = seal
						report["policy"] = policy
						report["seed"] = seed
						file.store_line(JSON.stringify(report))
						count += 1
	file.close()
	print("fast balance: %d runs in %.1f s -> %s" % [count, (Time.get_ticks_msec() - started) / 1000.0, args.out])


## Grid search: the coefficients whose simulated per-wave kill and damage ratios
## (median by configuration and wave) and outcomes best match the real runs.
func _calibrate(folder: String) -> void:
	var real := _load_real(folder.path_join("runs"))
	print("calibration on %d real runs" % real.size())
	var best := {}
	var best_loss := INF
	for k_kill in GRID.k_kill:
		for k_area in GRID.k_area:
			for f_hit in GRID.f_hit:
				for p_exp in GRID.p_exp:
					var params := {"k_kill": k_kill, "k_area": k_area, "f_hit": f_hit, "p_exp": p_exp}
					var loss := _loss(real, params)
					if loss < best_loss:
						best_loss = loss
						best = params
	best["loss"] = best_loss
	best["real_runs"] = real.size()
	var file := FileAccess.open(CALIBRATION, FileAccess.WRITE)
	file.store_string(JSON.stringify(best, "\t"))
	file.close()
	print("calibration: ", best)


func _loss(real: Array, params: Dictionary) -> float:
	var loss := 0.0
	for run in real:
		var character: CharacterData = ContentDB.get_def(&"characters", StringName(run.character))
		var weapon: WeaponData = ContentDB.get_def(&"weapons", StringName(run.weapon))
		var sims := []
		for seed in CALIBRATION_SEEDS:
			sims.append(_new_sim(character, weapon, int(run.seal), String(run.policy), 100 + seed, params).play())
		# Outcome: reached wave (fraction of the run).
		var reached := 0.0
		for s in sims:
			reached += s.wave_reached
		loss += absf(reached / sims.size() - float(run.wave_reached)) / 20.0 * 3.0
		# Per wave: kill ratio and damage ratio, waves both played.
		for w in run.waves:
			var kills := []
			var damage := []
			for s in sims:
				if w.wave <= s.waves.size():
					kills.append(s.waves[w.wave - 1].kill_ratio)
					damage.append(s.waves[w.wave - 1].damage_ratio)
			if kills.is_empty():
				continue
			kills.sort()
			damage.sort()
			loss += absf(kills[kills.size() / 2] - minf(w.kill_ratio, 1.0)) * 0.5
			loss += absf(minf(damage[damage.size() / 2], 1.5) - minf(w.damage_ratio, 1.5))
	return loss


## Diagnostic: one real run next to its simulation, wave by wave.
func _compare(path: String) -> void:
	var run: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var sim := _new_sim(ContentDB.get_def(&"characters", StringName(run.character)),
		ContentDB.get_def(&"weapons", StringName(run.weapon)), int(run.seal), String(run.policy), 1,
		load_calibration()).play()
	print("wave | real: spawned kill dmg dps lvl mat | sim: spawned kill dmg dps lvl mat pressure")
	for i in maxi(run.waves.size(), sim.waves.size()):
		var r: Dictionary = run.waves[i] if i < run.waves.size() else {}
		var s: Dictionary = sim.waves[i] if i < sim.waves.size() else {}
		print("%2d | %4d %.2f %.2f %6d %2d %5d | %4d %.2f %.2f %6d %2d %5d %.2f" % [i + 1,
			r.get("spawned", 0), r.get("kill_ratio", 0.0), r.get("damage_ratio", 0.0), r.get("sheet_dps", 0.0),
			r.get("level", 0), r.get("materials", 0),
			s.get("spawned", 0), s.get("kill_ratio", 0.0), s.get("damage_ratio", 0.0), s.get("sheet_dps", 0.0),
			s.get("level", 0), s.get("materials", 0), s.get("pressure", 0.0)])


static func _load_real(folder: String) -> Array:
	var runs := []
	for f in DirAccess.get_files_at(folder):
		if not f.ends_with(".json"):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join(f)))
		if data is Dictionary and data.get("outcome") in ["won", "died"]:
			runs.append(data)
	return runs


static func _range(spec: String) -> Array[int]:
	var out: Array[int] = []
	if spec.contains("-"):
		var parts := spec.split("-")
		for v in range(int(parts[0]), int(parts[1]) + 1):
			out.append(v)
	else:
		for v in spec.split(","):
			out.append(int(v))
	return out
