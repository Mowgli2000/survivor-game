class_name Run
extends Node2D
## Composition root of a run: creates every run system, wires their signals,
## and handles the run flow (level-up pause, game over, retry).
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
var progression: Progression
var player: Player
var enemies: EnemyManager
var enemy_projectiles: EnemyProjectileManager
var projectiles: ProjectileManager
var pickups: PickupManager
var spawner: SpawnDirector
var vfx: Vfx
var damage_numbers: DamageNumbers
var hud: Hud
var level_up_screen: LevelUpScreen
var game_over_screen: GameOverScreen

var _upgrade_pool: Array[UpgradeData] = []
var _weapon_pool: Array[WeaponData] = []
var _choosing: bool = false


func _ready() -> void:
	if config == null:
		config = ContentDB.get_def(&"runs", DEFAULT_CONFIG_ID)
	assert(config != null, "Run: no RunConfig (expected data/runs/default.tres)")
	var arena_rect := Rect2(-config.arena_size * 0.5, config.arena_size)

	state = RunState.new(seed_override if seed_override >= 0 else randi())
	progression = Progression.new(config.xp_base, config.xp_exponent)
	_upgrade_pool.assign(ContentDB.get_all(&"upgrades"))
	_weapon_pool.assign(ContentDB.get_all(&"weapons"))

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
	enemies.setup(player, arena_rect, mini(config.max_enemies, 200), state.rng, vfx, enemy_projectiles)
	add_child(enemies)

	projectiles = ProjectileManager.new()
	projectiles.name = "Projectiles"
	projectiles.setup(enemies, arena_rect, 100, vfx)
	add_child(projectiles)

	add_child(player)
	add_child(enemy_projectiles)
	add_child(vfx)
	add_child(damage_numbers)
	player.weapons.setup(WeaponContext.new(player, player.stats, enemies, projectiles, state.rng, vfx))
	if config.character.starting_weapon != null:
		player.weapons.add_weapon(config.character.starting_weapon)

	spawner = SpawnDirector.new()
	spawner.name = "SpawnDirector"
	spawner.setup(config, state, enemies, player, arena_rect)
	add_child(spawner)

	hud = Hud.new()
	add_child(hud)
	hud.setup(player, progression, state)

	level_up_screen = LevelUpScreen.new()
	add_child(level_up_screen)
	game_over_screen = GameOverScreen.new()
	add_child(game_over_screen)

	var overlay := DebugOverlay.new()
	overlay.setup(enemies, projectiles, pickups, enemy_projectiles, vfx)
	add_child(overlay)

	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.enemy_damaged.connect(damage_numbers.spawn)
	vfx.shake_requested.connect(player.camera.add_trauma)
	player.damaged.connect(func(_amount: float) -> void: player.camera.add_trauma(PLAYER_HIT_SHAKE))
	pickups.xp_collected.connect(progression.add_xp)
	progression.leveled_up.connect(_on_leveled_up)
	player.died.connect(_on_player_died)
	level_up_screen.offer_chosen.connect(_apply_offer)
	game_over_screen.retry_requested.connect(_on_retry_requested)


func _physics_process(delta: float) -> void:
	if not state.is_over:
		state.elapsed += delta


func _on_enemy_killed(data: EnemyData, pos: Vector2, _elite: bool) -> void:
	state.kills += 1
	pickups.spawn_xp(pos, data.xp_value)


func _on_leveled_up(_level: int) -> void:
	if not _choosing:
		_offer_upgrades()


func _offer_upgrades() -> void:
	var weapons := player.weapons
	var offers := progression.roll_offers(_upgrade_pool, _weapon_pool, weapons.owned_levels(),
		config.max_weapon_slots - weapons.slot_count(), config.upgrade_choices, state.rng,
		config.new_weapon_weight, config.weapon_level_weight)
	if offers.is_empty():
		progression.pending_level_ups = 0
		return
	if auto_choose_upgrades:
		_apply_offer(offers[0])
		return
	_choosing = true
	get_tree().paused = true
	level_up_screen.open(offers)


func _apply_offer(offer: UpgradeOffer) -> void:
	match offer.kind:
		UpgradeOffer.Kind.STAT:
			progression.apply_upgrade(offer.upgrade, player.stats)
		UpgradeOffer.Kind.NEW_WEAPON:
			player.weapons.add_weapon(offer.weapon)
			progression.consume_level_up()
		UpgradeOffer.Kind.WEAPON_LEVEL:
			player.weapons.level_up(offer.weapon)
			progression.consume_level_up()
	if progression.pending_level_ups > 0 and not state.is_over:
		_choosing = false
		_offer_upgrades()
		return
	_choosing = false
	level_up_screen.close()
	if not state.is_over:
		get_tree().paused = false


func _on_player_died() -> void:
	state.is_over = true
	get_tree().paused = true
	game_over_screen.open(state.elapsed, progression.level, state.kills)


func _on_retry_requested() -> void:
	get_tree().paused = false
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		retry_requested.emit()
