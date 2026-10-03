class_name Run
extends Node2D
## Composition root of a run: creates every run system, wires their signals,
## and handles the run flow (waves, between-waves screen, deferred level-ups,
## shop, game over, victory, retry).
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
var inventory: Inventory
var item_effects: ItemEffects
var hud: Hud
var level_up_screen: LevelUpScreen
var wave_end_screen: WaveEndScreen
var shop: Shop
var shop_screen: ShopScreen
var game_over_screen: GameOverScreen

var _upgrade_pool: Array[UpgradeData] = []
## Level-up rerolls paid during the current wave end (the cost grows each time).
var _level_up_rerolls: int = 0


func _ready() -> void:
	if config == null:
		config = ContentDB.get_def(&"runs", DEFAULT_CONFIG_ID)
	assert(config != null, "Run: no RunConfig (expected data/runs/default.tres)")
	stage = config.stage
	assert(stage != null, "Run: RunConfig has no stage")
	if config.shop == null:
		config.shop = ContentDB.get_def(&"shop", &"default")
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
	inventory = Inventory.new(player.stats)
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
	enemies.y_sort_enabled = true
	# Player and enemies share one y-sorted container: lower on screen = in front.
	var actors := Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
	actors.add_child(enemies)
	add_child(actors)

	projectiles = ProjectileManager.new()
	projectiles.name = "Projectiles"
	projectiles.setup(enemies, arena_rect, 100, vfx)
	add_child(projectiles)

	actors.add_child(player)
	player.camera.zoom = Vector2.ONE * config.camera_zoom
	player.weapon_visuals.setup(player.weapons, enemies, player)
	add_child(enemy_projectiles)
	add_child(vfx)
	add_child(damage_numbers)
	player.weapons.setup(WeaponContext.new(player, player.stats, enemies, projectiles, state.rng, vfx),
		config.max_weapon_slots)
	var weapon_pool: Array[WeaponData] = []
	weapon_pool.assign(ContentDB.get_all(&"weapons"))
	var item_pool: Array[ItemData] = []
	item_pool.assign(ContentDB.get_all(&"items"))
	shop = Shop.new(config.shop, state.wallet, inventory, player.weapons, weapon_pool, item_pool, state.rng)
	shop.luck_stats = player.stats
	player.rng = state.rng
	item_effects = ItemEffects.new()
	item_effects.name = "ItemEffects"
	item_effects.setup(player, enemies, state.wallet, state.rng, vfx)
	add_child(item_effects)
	inventory.item_added.connect(item_effects.add_item)
	state.wallet.add(config.shop.starting_materials)
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
	shop_screen = ShopScreen.new()
	add_child(shop_screen)
	shop_screen.setup(shop, state.wallet, inventory, player.weapons, player.stats)
	game_over_screen = GameOverScreen.new()
	add_child(game_over_screen)

	var overlay := DebugOverlay.new()
	overlay.setup(enemies, projectiles, pickups, enemy_projectiles, vfx)
	overlay.setup_waves(state, stage, waves)
	add_child(overlay)

	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.enemy_damaged.connect(damage_numbers.spawn)
	vfx.shake_requested.connect(func(amount: float) -> void:
		player.camera.add_trauma(amount, GameCamera.EXPLOSION_CAP))
	player.damaged.connect(_on_player_damaged)
	pickups.xp_collected.connect(progression.add_xp)
	pickups.xp_collected.connect(_on_materials_collected)
	player.died.connect(_on_player_died)
	level_up_screen.offer_chosen.connect(_apply_offer)
	level_up_screen.reroll_requested.connect(_on_level_up_reroll)
	game_over_screen.retry_requested.connect(_on_retry_requested)
	waves.wave_started.connect(spawner.begin_wave)
	waves.wave_ended.connect(_on_wave_ended)
	waves.run_won.connect(_on_run_won)
	shop_screen.next_wave_requested.connect(_start_next_wave)
	waves.wave_started.connect(func(_wave: int) -> void: Audio.play(Sounds.WAVE_START, -6.0))
	Audio.play_music(Sounds.MUSIC_RUN)
	waves.start_wave(1)


func _physics_process(delta: float) -> void:
	if not state.is_over and waves.in_wave:
		state.elapsed += delta


func _on_player_damaged(_amount: float) -> void:
	player.camera.add_trauma(PLAYER_HIT_SHAKE)
	Audio.play(Sounds.PLAYER_HURT, -4.0)


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
	item_effects.on_wave_ended(wave)
	player.heal(player.stats.get_value(StatIds.MAX_HP) * stage.heal_between_waves)
	if waves.is_last_wave():
		return  # _on_run_won follows
	Audio.play(Sounds.WAVE_END, -6.0)
	if not auto_choose_upgrades:
		get_tree().paused = true
		wave_end_screen.open(waves.wave)
	_level_up_rerolls = 0
	_resolve_level_ups()


## XP pickups are also materials, fewer per pickup as the run goes on.
func _on_materials_collected(amount: int) -> void:
	state.wallet.add_scaled(amount, stage.material_rate_at(waves.wave))


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
	var offers := progression.roll_offers(_upgrade_pool, config.upgrade_choices, state.rng,
		config.shop, waves.wave, player.stats.get_value(StatIds.LUCK))
	if offers.is_empty():
		progression.pending_level_ups = 0
		_on_level_ups_resolved()
		return
	if auto_choose_upgrades:
		_apply_offer(offers[0])
		return
	var cost := _level_up_reroll_cost()
	level_up_screen.open(offers, cost, state.wallet.can_afford(cost))


func _apply_offer(offer: UpgradeOffer) -> void:
	Audio.play(Sounds.LEVEL_UP, -6.0)
	progression.apply_offer(offer, player.stats)
	_resolve_level_ups()


func _level_up_reroll_cost() -> int:
	return config.shop.reroll_cost(waves.wave, _level_up_rerolls)


## Paid reroll of the current level-up cards (same cost rule as the shop).
func _on_level_up_reroll() -> void:
	if not state.wallet.spend(_level_up_reroll_cost()):
		Audio.play(Sounds.UI_ERROR, -8.0)
		return
	Audio.play(Sounds.UI_REROLL, -6.0)
	_level_up_rerolls += 1
	_resolve_level_ups()


func _on_level_ups_resolved() -> void:
	level_up_screen.close()
	shop.open(waves.wave)
	if auto_choose_upgrades:
		_auto_buy()
		_start_next_wave()
		return
	wave_end_screen.close()
	shop_screen.open()


## Bots and tests: buys the first affordable slot.
func _auto_buy() -> void:
	for i in shop.offers.size():
		if shop.buy(i):
			return


func _start_next_wave() -> void:
	wave_end_screen.close()
	shop_screen.close()
	get_tree().paused = false
	waves.start_wave(waves.wave + 1)


func _on_run_won() -> void:
	if state.is_over:
		return
	state.is_over = true
	Audio.stop_music()
	Audio.play(Sounds.VICTORY)
	get_tree().paused = true
	game_over_screen.open(state.elapsed, progression.level, state.kills, waves.wave, true)


func _on_player_died() -> void:
	state.is_over = true
	Audio.stop_music()
	Audio.play(Sounds.DEFEAT)
	get_tree().paused = true
	game_over_screen.open(state.elapsed, progression.level, state.kills, waves.wave)


func _on_retry_requested() -> void:
	get_tree().paused = false
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		retry_requested.emit()
