extends Node
## Balance simulator (ADR 0019): plays ONE full run headless with a bot (movement:
## BalanceBot, build: BalancePolicy) through the real game code, then writes one
## JSON report and quits. Run many in parallel with tools/balance/run_balance.py:
##   Godot.exe --headless --path . --fixed-fps 60 res://src/debug/balance/balance_sim.tscn --
##     --character=ronin --weapon=katana --seal=0 --policy=dps --seed=1 --out=<file.json>
## The run never touches the player profile and sees all content (unlock_all).
## --fixed-fps makes the engine simulate as fast as the CPU allows.

const RUN_SCENE := preload("res://src/run/run.tscn")
## Safety net: a stuck run is reported as a timeout (real seconds).
const MAX_REAL_SECONDS := 900.0

var _run: Run
var _policy: BalancePolicy
var _bot := BalanceBot.new()
var _out: String = "user://balance_run.json"
var _report: Dictionary = {}
var _waves: Array = []
var _damage_taken: float = 0.0
var _min_hp_ratio: float = 1.0
var _started_ms: int = 0
var _done: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := {"character": "drifter", "weapon": "", "seal": "0", "policy": "dps", "seed": "1"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--") and arg.contains("="):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			args[parts[0]] = parts[1]
	var character: CharacterData = ContentDB.get_def(&"characters", StringName(args.character))
	var difficulty: DifficultyData = ContentDB.get_def(&"difficulties", StringName("danger_%s" % args.seal))
	if character == null or difficulty == null:
		_fail("unknown character or seal: %s" % args)
		return
	var weapon: WeaponData = ContentDB.get_def(&"weapons", StringName(args.weapon)) if args.weapon != "" \
		else character.starting_weapons[0]
	var seed := int(args.seed)
	_policy = BalancePolicy.new(String(args.policy), seed)
	_report = {"character": String(character.id), "weapon": String(weapon.id), "seal": difficulty.level,
		"policy": _policy.kind, "seed": seed}
	var setup := RunSetup.new()
	setup.character = character
	setup.weapon = weapon
	setup.difficulty = difficulty
	_run = RUN_SCENE.instantiate()
	_run.setup = setup
	_run.seed_override = seed
	_run.auto_choose_upgrades = true
	_run.record_profile = false
	_run.unlock_all = true
	_run.bot_policy = self
	_run.bot_input = _bot.steer
	_bot.setup(_run)
	add_child(_run)
	_run.player.damaged.connect(_on_damaged)
	_run.player.died.connect(_on_died)
	_run.waves.run_won.connect(_on_won)
	_started_ms = Time.get_ticks_msec()


func _physics_process(_delta: float) -> void:
	if _done or _run == null:
		return
	var max_hp := _run.player.stats.get_value(StatIds.MAX_HP)
	_min_hp_ratio = minf(_min_hp_ratio, _run.player.hp / maxf(max_hp, 1.0))
	if (Time.get_ticks_msec() - _started_ms) / 1000.0 > MAX_REAL_SECONDS:
		_record_wave()
		_finish("timeout")


# --- Run.bot_policy (called between waves, before the next one starts) ---

func choose_upgrade(offers: Array[UpgradeOffer], rp: RunPlayer) -> UpgradeOffer:
	return _policy.choose_upgrade(offers, rp)


func shop_turn(rp: RunPlayer, wave: int) -> void:
	_record_wave()
	var before := rp.wallet.amount
	_policy.shop_turn(rp, wave)
	_waves[-1]["spent"] = before - rp.wallet.amount
	_waves[-1]["materials_after_shop"] = rp.wallet.amount


# --- Metrics ---

func _on_damaged(amount: float) -> void:
	_damage_taken += amount


func _on_died() -> void:
	_record_wave()
	_finish("died")


func _on_won() -> void:
	_record_wave()
	_finish("won")


func _record_wave() -> void:
	var state := _run.state
	var player := _run.player
	var max_hp := player.stats.get_value(StatIds.MAX_HP)
	var spawned := maxi(state.wave_spawned, 1)
	_waves.append({
		"wave": _run.waves.wave,
		"spawned": state.wave_spawned,
		"kills": state.wave_kills,
		"kill_ratio": float(state.wave_kills) / spawned,
		"damage_taken": _damage_taken,
		"damage_ratio": _damage_taken / maxf(max_hp, 1.0),
		"min_hp_ratio": _min_hp_ratio,
		"level": _run.progression.level,
		"materials": _run.players[0].wallet.amount,
		"weapons": _weapon_list(player.weapons),
		"items": _run.inventory.get_items().size(),
		"sheet_dps": sheet_dps(player.weapons, player.stats),
		"max_hp": max_hp,
		"stats": _stats(player.stats),
	})
	_policy.last_wave_damage_ratio = _damage_taken / maxf(max_hp, 1.0)
	_damage_taken = 0.0
	_min_hp_ratio = 1.0


## Damage per second written on the weapons (no positioning, no overkill):
## a trend indicator of build power, not a combat result.
static func sheet_dps(weapons: WeaponHolder, stats: StatBlock) -> float:
	var total := 0.0
	var crit := stats.get_value(StatIds.CRIT_CHANCE)
	var crit_mult := stats.get_value(StatIds.CRIT_DAMAGE)
	var count_bonus := stats.get_value(StatIds.PROJECTILE_COUNT)
	for slot in weapons.get_slots():
		var s := slot.stats
		var hits_per_second := stats.get_value(StatIds.ATTACK_SPEED) / maxf(s.cooldown, 0.05)
		var crit_factor := 1.0 + clampf(s.crit_chance + crit, 0.0, 1.0) * (crit_mult - 1.0)
		total += s.damage * stats.get_value(StatIds.DAMAGE) * crit_factor * hits_per_second \
			* maxf(s.projectile_count + count_bonus, 1.0)
	return total


static func _weapon_list(weapons: WeaponHolder) -> Array:
	var list := []
	for slot in weapons.get_slots():
		list.append("%s:%d" % [slot.data.id, slot.level])
	return list


static func _stats(stats: StatBlock) -> Dictionary:
	var out := {}
	for id in StatIds.DEFAULTS:
		out[String(id)] = snappedf(stats.get_value(id), 0.001)
	return out


func _finish(outcome: String) -> void:
	if _done:
		return
	_done = true
	_report["outcome"] = outcome
	_report["won"] = outcome == "won"
	_report["wave_reached"] = _run.waves.wave
	_report["real_seconds"] = (Time.get_ticks_msec() - _started_ms) / 1000.0
	_report["items"] = _item_list()
	_report["waves"] = _waves
	_write()


func _item_list() -> Array:
	var list := []
	for item in _run.inventory.get_items():
		list.append("%s:%d" % [item.id, _run.inventory.count(item)])
	return list


func _fail(message: String) -> void:
	_report = {"outcome": "error", "error": message}
	_write()


func _write() -> void:
	var file := FileAccess.open(_out, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_report))
		file.close()
	print("balance run: %s -> %s" % [_report.get("outcome"), _out])
	get_tree().quit()
