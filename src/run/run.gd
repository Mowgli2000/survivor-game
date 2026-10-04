class_name Run
extends Node2D
## Composition root of a run: creates every run system, wires their signals,
## and handles the run flow (waves, between-waves screen, deferred level-ups,
## shop, game over, victory, retry).
## Contains no gameplay rules itself.
##
## One or two players (local coop, ADR 0017): each owns a RunPlayer (player,
## progression, wallet, inventory, shop...). The single-player fields below
## (player, progression, shop...) are player 1's.

signal retry_requested

const DEFAULT_CONFIG_ID := &"default"
const PLAYER_HIT_SHAKE := 0.35
## Coop: players start this far apart, side by side.
const COOP_START_GAP := 120.0

## Leave empty to use data/runs/default.tres.
@export var config: RunConfig
## Negative = random seed.
@export var seed_override: int = -1

@export_group("Debug / tests")
@export var player_invincible: bool = false
## Picks the first offer automatically instead of pausing on level-up.
@export var auto_choose_upgrades: bool = false
## 2 = local coop with the config character for both (debug tools, tests).
## Menu runs use the setup instead (RunSetup.character_2).
@export_range(1, 2) var player_count: int = 1
## When valid, drives the players instead of the input (bots, tests, stress test).
var bot_input: Callable
## Balance simulator (ADR 0019): picks level-up cards and plays the shop when
## auto_choose_upgrades is on. Duck-typed: choose_upgrade(offers, rp) -> UpgradeOffer
## and shop_turn(rp, wave). Null: first card, first affordable offer.
var bot_policy: Object
## False: the run never touches the player profile (simulations).
var record_profile: bool = true
## True: every weapon and item can show up, whatever the profile unlocked.
var unlock_all: bool = false
## Character and weapon chosen in the menu (SceneRouter.next_run when null).
## Only runs with a setup are recorded in the profile: tests and debug
## tools instantiate run.tscn without one.
var setup: RunSetup

var state: RunState
var stage: StageData
var players: Array[RunPlayer] = []
var party: Party
var camera: GameCamera
var progression: Progression
var player: Player
var enemies: EnemyManager
var enemy_projectiles: EnemyProjectileManager
var projectiles: ProjectileManager
var pickups: PickupManager
var spawner: SpawnDirector
var bosses: BossDirector
var waves: WaveDirector
var vfx: Vfx
var damage_numbers: DamageNumbers
var inventory: Inventory
var item_effects: ItemEffects
var weapon_families: WeaponFamilies
var hud: Hud
var level_up_screen: LevelUpScreen
var wave_end_screen: WaveEndScreen
var shop: Shop
var shop_screen: ShopScreen
var game_over_screen: GameOverScreen
var pause_menu: PauseMenu

var _upgrade_pool: Array[UpgradeData] = []
var _character: CharacterData
var _killed_special: Array[StringName] = []
## Player whose level-ups and shop are open between waves (coop: one after the other).
var _turn: int = 0


func _ready() -> void:
	if config == null:
		config = ContentDB.get_def(&"runs", DEFAULT_CONFIG_ID)
	assert(config != null, "Run: no RunConfig (expected data/runs/default.tres)")
	assert(config.stage != null, "Run: RunConfig has no stage")
	if config.shop == null:
		config.shop = ContentDB.get_def(&"shop", &"default")
	var arena_rect := Rect2(-config.arena_size * 0.5, config.arena_size)

	# Launched as a scene (menu, Restart): directly under the root. Tests and
	# debug tools add run.tscn under their own node and pass their own setup.
	if setup == null and get_parent() == get_tree().root:
		setup = SceneRouter.next_run
	_character = setup.character if setup != null and setup.character != null else config.character
	# Always a copy: difficulty and endless mode change it, never the shared data.
	stage = config.stage.with_difficulty(setup.difficulty if setup != null else null)
	if is_coop():
		stage.apply_coop(config.coop_spawn_multiplier, config.coop_hp_multiplier)
	state = RunState.new(seed_override if seed_override >= 0 else randi())
	progression = Progression.new(config.xp_base, config.xp_exponent)
	_upgrade_pool.assign(ContentDB.get_all(&"upgrades"))

	var arena := Arena.new()
	arena.setup(arena_rect, setup.difficulty.biome if setup != null and setup.difficulty != null else null)
	add_child(arena)

	vfx = Vfx.new()
	vfx.name = "Vfx"
	damage_numbers = DamageNumbers.new()
	damage_numbers.name = "DamageNumbers"

	_create_players(arena_rect)

	pickups = PickupManager.new()
	pickups.name = "Pickups"
	pickups.setup(party, config.max_xp_gems)
	add_child(pickups)

	enemy_projectiles = EnemyProjectileManager.new()
	enemy_projectiles.name = "EnemyProjectiles"
	enemy_projectiles.setup(party, arena_rect)

	enemies = EnemyManager.new()
	enemies.name = "Enemies"
	enemies.setup(party, arena_rect, mini(stage.max_enemies, 200), state.rng, vfx, enemy_projectiles)
	enemies.elite_scale = stage.elite_scale
	enemies.spawn_cap = stage.max_enemies
	enemies.y_sort_enabled = true
	# Players and enemies share one y-sorted container: lower on screen = in front.
	var actors := Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
	actors.add_child(enemies)
	add_child(actors)

	projectiles = ProjectileManager.new()
	projectiles.name = "Projectiles"
	projectiles.setup(enemies, arena_rect, 100, vfx)
	add_child(projectiles)

	for rp in players:
		actors.add_child(rp.player)
		rp.player.weapon_visuals.setup(rp.player.weapons, enemies, rp.player)
	camera = GameCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.follow(party, config.camera_zoom)
	add_child(enemy_projectiles)
	add_child(vfx)
	add_child(damage_numbers)

	var weapon_pool: Array[WeaponData] = []
	weapon_pool.assign(_unlocked(&"weapons"))
	var item_pool: Array[ItemData] = []
	item_pool.assign(_unlocked(&"items"))
	var families: Array[FamilyData] = []
	families.assign(ContentDB.get_all(&"families"))
	for rp in players:
		_equip_player(rp, weapon_pool, item_pool, families)
	shop = players[0].shop
	weapon_families = players[0].families
	item_effects = players[0].item_effects

	waves = WaveDirector.new()
	waves.name = "WaveDirector"
	waves.setup(stage)
	add_child(waves)

	spawner = SpawnDirector.new()
	spawner.name = "SpawnDirector"
	spawner.setup(stage, state, enemies, party, arena_rect, waves)
	add_child(spawner)

	bosses = BossDirector.new()
	bosses.name = "BossDirector"
	bosses.setup(enemies, enemy_projectiles, party, vfx, state.rng, stage, waves)
	add_child(bosses)

	hud = Hud.new()
	add_child(hud)
	hud.setup_boss(bosses)
	hud.setup(player, progression, waves, state.wallet)
	hud.setup_families(weapon_families)
	if players.size() > 1:
		var second := players[1]
		hud.setup_second_player(second.player, second.progression, second.wallet, second.color())

	level_up_screen = LevelUpScreen.new()
	add_child(level_up_screen)
	wave_end_screen = WaveEndScreen.new()
	add_child(wave_end_screen)
	for rp in players:
		rp.shop_screen = ShopScreen.new()
		add_child(rp.shop_screen)
		rp.shop_screen.setup(rp.shop, rp.wallet, rp.inventory, rp.player.weapons, rp.player.stats)
		rp.shop_screen.stats_panel.setup_families(rp.families)
		rp.shop_screen.next_wave_requested.connect(_on_shop_done)
	shop_screen = players[0].shop_screen
	game_over_screen = GameOverScreen.new()
	add_child(game_over_screen)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.stats_panel.setup(player.stats)
	pause_menu.stats_panel.setup_families(weapon_families)
	if is_coop():
		var gate := CoopInputGate.new()
		gate.setup(_input_owner)
		add_child(gate)

	var overlay := DebugOverlay.new()
	overlay.setup(enemies, projectiles, pickups, enemy_projectiles, vfx)
	overlay.setup_waves(state, stage, waves)
	if is_coop():
		overlay.move_below_hud(230.0)
	add_child(overlay)

	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.enemy_damaged.connect(damage_numbers.spawn)
	vfx.shake_requested.connect(func(amount: float) -> void:
		camera.add_trauma(amount, GameCamera.EXPLOSION_CAP))
	for rp in players:
		rp.player.damaged.connect(_on_player_damaged)
		rp.player.died.connect(_on_player_died)
	pickups.xp_collected.connect(_on_xp_collected)
	level_up_screen.offer_chosen.connect(_apply_offer)
	level_up_screen.reroll_requested.connect(_on_level_up_reroll)
	game_over_screen.retry_requested.connect(_on_retry_requested)
	game_over_screen.endless_requested.connect(_continue_endless)
	game_over_screen.main_menu_requested.connect(SceneRouter.goto_main_menu)
	pause_menu.resume_requested.connect(_resume_from_pause)
	pause_menu.restart_requested.connect(_on_retry_requested)
	pause_menu.main_menu_requested.connect(SceneRouter.goto_main_menu)
	pause_menu.quit_requested.connect(SceneRouter.quit)
	Settings.changed.connect(_apply_settings)
	_apply_settings()
	waves.wave_started.connect(spawner.begin_wave)
	waves.wave_ended.connect(_on_wave_ended)
	waves.run_won.connect(_on_run_won)
	waves.wave_started.connect(func(_wave: int) -> void: Audio.play(Sounds.WAVE_START, -6.0))
	Audio.play_music(Sounds.MUSIC_RUN)
	waves.start_wave(1)


## Two players: chosen in the menu (setup.character_2) or forced by player_count.
func is_coop() -> bool:
	return player_count > 1 or (setup != null and setup.character_2 != null)


## Player whose between-waves screens are open.
func current_player() -> RunPlayer:
	return players[_turn]


## Players with their input, progression and wallet (systems come in _equip_player).
func _create_players(arena_rect: Rect2) -> void:
	var count := 2 if is_coop() else 1
	var inputs := PlayerInput.assign(count, PlayerInput.connected_pads())
	party = Party.new()
	for i in count:
		var rp := RunPlayer.new()
		rp.index = i
		rp.character = _character if i == 0 else _second_character()
		rp.input = inputs[i]
		var p := Player.new()
		p.name = "Player" if i == 0 else "Player%d" % (i + 1)
		p.index = i
		p.setup(rp.character, arena_rect)
		p.invincible = player_invincible
		p.bot_input = bot_input
		p.input = rp.input
		p.party = party
		if count > 1:
			p.position = Vector2(COOP_START_GAP * (i - 0.5), 0.0)
			p.tag_color = rp.color()
		rp.player = p
		rp.progression = progression if i == 0 else Progression.new(config.xp_base, config.xp_exponent)
		rp.wallet = state.wallet if i == 0 else Wallet.new()
		rp.inventory = Inventory.new(p.stats)
		party.add(p)
		players.append(rp)
	player = players[0].player
	inventory = players[0].inventory


func _second_character() -> CharacterData:
	if setup != null and setup.character_2 != null:
		return setup.character_2
	return config.character


## Weapons, shop, families, item effects, character rules and starting weapon of `rp`.
func _equip_player(rp: RunPlayer, weapon_pool: Array[WeaponData], item_pool: Array[ItemData],
		families: Array[FamilyData]) -> void:
	var p := rp.player
	var ctx := WeaponContext.new(p, p.stats, enemies, projectiles, state.rng, vfx)
	ctx.source = rp.index
	p.weapons.setup(ctx, config.max_weapon_slots)
	p.weapons.favored_family = rp.character.favored_family
	p.weapons.off_family_scale = rp.character.off_family_damage_scale
	# Class rule: only the weapons this character may use are sold to it.
	var allowed_weapons: Array[WeaponData] = []
	allowed_weapons.assign(weapon_pool.filter(rp.character.allows_weapon))
	rp.shop = Shop.new(config.shop, rp.wallet, rp.inventory, p.weapons, allowed_weapons, item_pool, state.rng)
	rp.shop.price_multiplier = rp.character.shop_price_multiplier
	rp.shop.reroll_multiplier = rp.character.reroll_cost_multiplier
	rp.shop.luck_stats = p.stats
	rp.families = WeaponFamilies.new()
	rp.families.setup(p.weapons, p.stats, families)
	p.rng = state.rng
	rp.item_effects = ItemEffects.new()
	rp.item_effects.name = "ItemEffects" if rp.index == 0 else "ItemEffects%d" % (rp.index + 1)
	rp.item_effects.setup(p, enemies, rp.wallet, state.rng, vfx)
	add_child(rp.item_effects)
	rp.inventory.item_added.connect(rp.item_effects.add_item)
	for mod in rp.character.modifiers:
		p.stats.add_modifier(mod)
	rp.item_effects.add_effects(rp.character.effects)
	rp.wallet.changed.connect(func(amount: int) -> void: rp.max_materials = maxi(rp.max_materials, amount))
	rp.wallet.add(config.shop.starting_materials)
	var weapon := _starting_weapon(rp)
	if weapon != null:
		p.weapons.add_weapon(weapon)


func _starting_weapon(rp: RunPlayer) -> WeaponData:
	if setup != null:
		var chosen := setup.weapon if rp.index == 0 else setup.weapon_2
		if chosen != null:
			return chosen
	return rp.character.starting_weapon


func _physics_process(delta: float) -> void:
	if not state.is_over and waves.in_wave:
		state.elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and can_pause():
		get_viewport().set_input_as_handled()
		open_pause()


## Only during a wave, with no other screen (level-up, shop, game over) open.
func can_pause() -> bool:
	return waves.in_wave and not state.is_over and not get_tree().paused and not auto_choose_upgrades


func open_pause() -> void:
	get_tree().paused = true
	pause_menu.open()


func _resume_from_pause() -> void:
	pause_menu.close()
	get_tree().paused = false


## Coop: between waves, only the devices of the player whose turn it is drive the screens.
## Null = every device (during waves, pause, game over).
func _input_owner() -> PlayerInput:
	if level_up_screen.visible or current_player().shop_screen.visible:
		return current_player().input
	return null


## Player settings that affect the run's feedback (damage numbers, screen shake).
func _apply_settings() -> void:
	damage_numbers.enabled = Settings.data.damage_numbers
	camera.shake_enabled = Settings.data.screen_shake


func _on_player_damaged(_amount: float) -> void:
	camera.add_trauma(PLAYER_HIT_SHAKE)
	Audio.play(Sounds.PLAYER_HURT, -4.0)


func _on_enemy_killed(data: EnemyData, pos: Vector2, elite: bool) -> void:
	state.kills += 1
	state.wave_kills += 1
	var xp := data.xp_value
	if elite:
		xp = roundi(xp * stage.elite_xp_multiplier)
	pickups.spawn_xp(pos, xp)
	if data.boss or not data.phases.is_empty():
		_killed_special.append(data.id)
	if data.reward_item_tier > 0:
		_grant_reward(data.reward_item_tier)
	if data.boss and not enemies.has_living_boss():
		waves.finish_wave()


## XP gems are also materials, fewer per gem as the run goes on. The end-of-wave
## sweep (SHARED) is split evenly between the players.
func _on_xp_collected(amount: int, collector: int) -> void:
	if collector != PickupManager.SHARED:
		_give_xp(players[collector], amount)
		return
	var share := ceili(float(amount) / players.size())
	for rp in players:
		_give_xp(rp, share)


func _give_xp(rp: RunPlayer, amount: int) -> void:
	rp.progression.add_xp(amount)
	rp.wallet.add_scaled(amount, stage.material_rate_at(waves.wave))


## Content of `category` the profile allows (locked content stays out).
func _unlocked(category: StringName) -> Array[Resource]:
	var list: Array[Resource] = []
	for def in ContentDB.get_all(category):
		if unlock_all or SaveService.is_unlocked(category, def):
			list.append(def)
	return list


## Menu runs only: profile statistics, challenges, unlocks shown on the end screen.
## Coop: recorded once per player's character.
func _record_run(won: bool) -> void:
	if setup == null or not record_profile:
		return
	var unlocks: Array[ChallengeData] = []
	for rp in players:
		var result := RunResult.new()
		result.character_id = rp.character.id
		result.won = won
		result.difficulty = setup.difficulty.level if setup.difficulty != null else 0
		result.wave = waves.wave
		result.kills = state.kills
		result.max_materials = maxi(rp.max_materials, rp.wallet.amount)
		result.killed_special = _killed_special
		for unlock in SaveService.record_run(result):
			if not unlocks.has(unlock):
				unlocks.append(unlock)
	game_over_screen.show_unlocks(unlocks)


## Boss reward: each player gets a random item of `min_tier` or higher they can still own.
func _grant_reward(min_tier: int) -> void:
	var pool: Array[ItemData] = []
	pool.assign(_unlocked(&"items"))
	var names: PackedStringArray = []
	for rp in players:
		var item := pick_reward(pool, rp.inventory, min_tier, state.rng)
		if item == null:
			continue
		rp.inventory.add(item)
		names.append(tr(item.name_key))
	if names.is_empty():
		return
	Audio.play(Sounds.LEVEL_UP, -4.0)
	hud.show_toast(tr("UI_BOSS_REWARD") % " / ".join(names))


static func pick_reward(pool: Array[ItemData], owned: Inventory, min_tier: int,
		rng: RandomNumberGenerator) -> ItemData:
	var choices: Array[ItemData] = []
	for item in pool:
		if item.tier >= min_tier and owned.can_add(item):
			choices.append(item)
	if choices.is_empty():
		return null
	return choices[rng.randi_range(0, choices.size() - 1)]


## End of a wave: clear the arena, collect gems, heal, then each player's
## level-ups and shop (one player after the other in coop).
func _on_wave_ended(wave: int) -> void:
	if state.is_over:
		return
	_log_wave_stats(wave)
	enemies.clear_all()
	enemy_projectiles.clear_all()
	pickups.collect_all()
	for rp in players:
		rp.item_effects.on_wave_ended(wave)
		rp.player.heal(rp.player.stats.get_value(StatIds.MAX_HP) * stage.heal_between_waves)
	if waves.is_last_wave():
		return  # _on_run_won follows
	Audio.play(Sounds.WAVE_END, -6.0)
	if not auto_choose_upgrades:
		get_tree().paused = true
		wave_end_screen.open(waves.wave)
	_begin_turn(0)


## Balancing aid (debug builds): one line per wave in the output console.
func _log_wave_stats(wave: int) -> void:
	if not OS.is_debug_build():
		return
	var spawned := maxi(state.wave_spawned, 1)
	print("[wave %d] %ds | spawned %d | killed %d (%d%%) | left %d | level %d" % [
		wave, roundi(stage.duration_at(wave)), state.wave_spawned, state.wave_kills,
		roundi(100.0 * state.wave_kills / spawned), enemies.active_count(), progression.level])


## Between waves: level-ups then shop of player `index`.
func _begin_turn(index: int) -> void:
	_turn = index
	current_player().level_up_rerolls = 0
	var tag := tr("UI_PLAYER_N") % (index + 1) if players.size() > 1 else ""
	level_up_screen.set_player_tag(tag, current_player().color())
	current_player().shop_screen.set_player_tag(tag, current_player().color())
	_resolve_level_ups()


## Offers one level-up at a time until none is pending.
func _resolve_level_ups() -> void:
	var rp := current_player()
	if rp.progression.pending_level_ups <= 0:
		_on_level_ups_resolved()
		return
	var offers := rp.progression.roll_offers(_upgrade_pool, config.upgrade_choices, state.rng,
		config.shop, waves.wave, rp.player.stats.get_value(StatIds.LUCK))
	if offers.is_empty():
		rp.progression.pending_level_ups = 0
		_on_level_ups_resolved()
		return
	for offer in offers:
		offer.bonus_scale = rp.character.upgrade_scale
	if auto_choose_upgrades:
		_apply_offer(bot_policy.choose_upgrade(offers, rp) if bot_policy != null else offers[0])
		return
	var cost := _level_up_reroll_cost()
	level_up_screen.open(offers, cost, rp.wallet.can_afford(cost), rp.player.stats)


func _apply_offer(offer: UpgradeOffer) -> void:
	Audio.play(Sounds.LEVEL_UP, -6.0)
	current_player().progression.apply_offer(offer, current_player().player.stats)
	_resolve_level_ups()


func _level_up_reroll_cost() -> int:
	return current_player().shop.scaled_reroll_cost(
		config.shop.reroll_cost(waves.wave, current_player().level_up_rerolls))


## Paid reroll of the current level-up cards (same cost rule as the shop).
func _on_level_up_reroll() -> void:
	if not current_player().wallet.spend(_level_up_reroll_cost()):
		Audio.play(Sounds.UI_ERROR, -8.0)
		return
	Audio.play(Sounds.UI_REROLL, -6.0)
	current_player().level_up_rerolls += 1
	_resolve_level_ups()


func _on_level_ups_resolved() -> void:
	level_up_screen.close()
	var rp := current_player()
	rp.shop.open(waves.wave)
	if auto_choose_upgrades:
		if bot_policy != null:
			bot_policy.shop_turn(rp, waves.wave)
		else:
			_auto_buy(rp)
		_on_shop_done()
		return
	wave_end_screen.close()
	rp.shop_screen.open()


## Bots and tests: buys the first affordable slot.
func _auto_buy(rp: RunPlayer) -> void:
	for i in rp.shop.offers.size():
		if rp.shop.buy(i):
			return


## "Next wave" in a shop: the next player's turn, or the next wave.
func _on_shop_done() -> void:
	current_player().shop_screen.close()
	if _turn + 1 < players.size():
		_begin_turn(_turn + 1)
		return
	_start_next_wave()


func _start_next_wave() -> void:
	wave_end_screen.close()
	for rp in players:
		rp.shop_screen.close()
		rp.player.revive()  # coop: the dead come back for the new wave
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
	_record_run(true)


## Coop: a dead player waits for the next wave; the run ends when nobody is left.
func _on_player_died() -> void:
	if party.alive_count() > 0:
		Audio.play(Sounds.DEFEAT, -8.0)
		return
	state.is_over = true
	Audio.stop_music()
	Audio.play(Sounds.DEFEAT)
	get_tree().paused = true
	game_over_screen.open(state.elapsed, progression.level, state.kills, waves.wave)
	if stage.endless:
		# The run was recorded at the victory: only the endless record remains.
		if setup != null:
			for rp in players:
				SaveService.record_endless(rp.character.id, waves.wave)
	else:
		_record_run(false)


## After a victory: the waves go on (level-ups, shop, wave 21...) until death.
func _continue_endless() -> void:
	stage.endless = true
	state.is_over = false
	game_over_screen.close()
	Audio.play_music(Sounds.MUSIC_RUN)
	_begin_turn(0)


func _on_retry_requested() -> void:
	get_tree().paused = false
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		retry_requested.emit()
