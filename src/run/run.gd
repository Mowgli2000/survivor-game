class_name Run
extends Node2D
## Composition root of a run: creates every run system, wires their signals,
## and handles the run flow (waves, between-waves screen and deferred
## level-ups, game over, victory, retry).
## Contains no gameplay rules itself.

signal retry_requested

const DEFAULT_CONFIG_ID := &"default"
const PLAYER_HIT_SHAKE := 0.35

## Leave empty to use data/runs/default.tres.
@export var config: RunConfig
## Negative = random seed.
@export var seed_override: int = -1

@export_group("Debug / tests")
@export var player_invincible: bool = false
## Picks the first offer automatically instead of pausing on level-up.
@export var auto_choose_upgrades: bool = false
## When valid, drives the player instead of the input (bots, tests, stress test).
var bot_input: Callable

var state: RunState
var stage: StageData
var progression: Progression
var player: Player
var enemies: EnemyManager
var enemy_projectiles: EnemyProjectileManager
var projectiles: ProjectileManager
var pickups: PickupManager
var spawner: SpawnDirector
var waves: WaveDirector
var vfx: Vfx
var damage_numbers: DamageNumbers
var hud: Hud
var level_up_screen: LevelUpScreen
var wave_end_screen: WaveEndScreen
var game_over_screen: GameOverScreen

var _upgrade_pool: Array[UpgradeData] = []


func _ready() -> void:
	if config == null:
		config = ContentDB.get_def(&"runs", DEFAULT_CONFIG_ID)
	assert(config != null, "Run: no RunConfig (expected data/runs/default.tres)")
	stage = config.stage
	assert(stage != null, "Run: RunConfig has no stage")
	var arena_rect := Rect2(-config.arena_size * 0.5, config.arena_size)

	state = RunState.new(seed_override if seed_override >= 0 else randi())
	progression = Progression.new(config.xp_base, config.xp_exponent)
	_upgrade_pool.assign(ContentDB.get_all(&"upgrades"))

	var arena := Arena.new()
	arena.setup(arena_rect)
	add_child(arena)

	vfx = Vfx.new()
	vfx.name = "Vfx"
	damage_numbers = DamageNumbers.new()
	damage_numbers.name = "DamageNumbers"

	player = Player.new()
	player.name = "Player"
	player.setup(config.character, arena_rect)
	player.invincible = player_invincible
	player.bot_input = bot_input

	pickups = PickupManager.new()
	pickups.name = "Pickups"
	pickups.setup(player, config.max_xp_gems)
	add_child(pickups)

	enemy_projectiles = EnemyProjectileManager.new()
	enemy_projectiles.name = "EnemyProjectiles"
	enemy_projectiles.setup(player, arena_rect)

	enemies = EnemyManager.new()
	enemies.name = "Enemies"
	enemies.setup(player, arena_rect, mini(stage.max_enemies, 200), state.rng, vfx, enemy_projectiles)
	enemies.elite_scale = stage.elite_scale
	add_child(enemies)

	projectiles = ProjectileManager.new()
	projectiles.name = "Projectiles"
	projectiles.setup(enemies, arena_rect, 100, vfx)
	add_child(projectiles)

	add_child(player)
	add_child(enemy_projectiles)
	add_child(vfx)
	add_child(damage_numbers)
	player.weapons.setup(WeaponContext.new(player, player.stats, enemies, projectiles, state.rng, vfx),
		config.max_weapon_slots)
	if config.character.starting_weapon != null:
		player.weapons.add_weapon(config.character.starting_weapon)

	waves = WaveDirector.new()
	waves.name = "WaveDirector"
	waves.setup(stage)
	add_child(waves)

	spawner = SpawnDirector.new()
	spawner.name = "SpawnDirector"
	spawner.setup(stage, state, enemies, player, arena_rect, waves)
	add_child(spawner)

	hud = Hud.new()
	add_child(hud)
	hud.setup(player, progression, waves, state.wallet)

	level_up_screen = LevelUpScreen.new()
	add_child(level_up_screen)
	wave_end_screen = WaveEndScreen.new()
	add_child(wave_end_screen)
	game_over_screen = GameOverScreen.new()
	add_child(game_over_screen)

	var overlay := DebugOverlay.new()
	overlay.setup(enemies, projectiles, pickups, enemy_projectiles, vfx)
	overlay.setup_waves(state, stage, waves)
	add_child(overlay)

	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.enemy_damaged.connect(damage_numbers.spawn)
	vfx.shake_requested.connect(player.camera.add_trauma)
	player.damaged.connect(func(_amount: float) -> void: player.camera.add_trauma(PLAYER_HIT_SHAKE))
	pickups.xp_collected.connect(progression.add_xp)
	pickups.xp_collected.connect(state.wallet.add)
	player.died.connect(_on_player_died)
	level_up_screen.offer_chosen.connect(_apply_offer)
	game_over_screen.retry_requested.connect(_on_retry_requested)
	waves.wave_started.connect(spawner.begin_wave)
	waves.wave_ended.connect(_on_wave_ended)
	waves.run_won.connect(_on_run_won)
	wave_end_screen.next_wave_requested.connect(_start_next_wave)
	waves.start_wave(1)


func _physics_process(delta: float) -> void:
	if not state.is_over and waves.in_wave:
		state.elapsed += delta


func _on_enemy_killed(data: EnemyData, pos: Vector2, elite: bool) -> void:
	state.kills += 1
	state.wave_kills += 1
	var xp := data.xp_value
	if elite:
		xp = roundi(xp * stage.elite_xp_multiplier)
	pickups.spawn_xp(pos, xp)
	if data.boss and not enemies.has_living_boss():
		waves.finish_wave()


## End of a wave: clear the arena, collect gems, heal, then resolve level-ups.
func _on_wave_ended(wave: int) -> void:
	if state.is_over:
		return
	_log_wave_stats(wave)
	enemies.clear_all()
	enemy_projectiles.clear_all()
	pickups.collect_all()
	player.heal(player.stats.get_value(StatIds.MAX_HP) * stage.heal_between_waves)
	if waves.is_last_wave():
		return  # _on_run_won follows
	if not auto_choose_upgrades:
		get_tree().paused = true
		wave_end_screen.open(waves.wave)
	_resolve_level_ups()


## Balancing aid (debug builds): one line per wave in the output console.
func _log_wave_stats(wave: int) -> void:
	if not OS.is_debug_build():
		return
	var spawned := maxi(state.wave_spawned, 1)
	print("[wave %d] %ds | spawned %d | killed %d (%d%%) | left %d | level %d" % [
		wave, roundi(stage.duration_at(wave)), state.wave_spawned, state.wave_kills,
		roundi(100.0 * state.wave_kills / spawned), enemies.active_count(), progression.level])


## Offers one level-up at a time until none is pending.
func _resolve_level_ups() -> void:
	if progression.pending_level_ups <= 0:
		_on_level_ups_resolved()
		return
	var offers := progression.roll_offers(_upgrade_pool, config.upgrade_choices, state.rng)
	if offers.is_empty():
		progression.pending_level_ups = 0
		_on_level_ups_resolved()
		return
	if auto_choose_upgrades:
		_apply_offer(offers[0])
		return
	level_up_screen.open(offers)


func _apply_offer(offer: UpgradeOffer) -> void:
	progression.apply_upgrade(offer.upgrade, player.stats)
	_resolve_level_ups()


func _on_level_ups_resolved() -> void:
	level_up_screen.close()
	if auto_choose_upgrades:
		_start_next_wave()
	else:
		wave_end_screen.show_next_button()


func _start_next_wave() -> void:
	wave_end_screen.close()
	get_tree().paused = false
	waves.start_wave(waves.wave + 1)


func _on_run_won() -> void:
	if state.is_over:
		return
	state.is_over = true
	get_tree().paused = true
	game_over_screen.open(state.elapsed, progression.level, state.kills, waves.wave, true)


func _on_player_died() -> void:
	state.is_over = true
	get_tree().paused = true
	game_over_screen.open(state.elapsed, progression.level, state.kills, waves.wave)


func _on_retry_requested() -> void:
	get_tree().paused = false
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		retry_requested.emit()
