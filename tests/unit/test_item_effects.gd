extends GutTest
## New stats (dodge, lifesteal, luck, harvest), the ItemEffects system and item effects.

var _player: Player
var _enemies: EnemyManager
var _wallet: Wallet
var _effects: ItemEffects


func before_each() -> void:
	var arena := Rect2(-1000, -1000, 2000, 2000)
	var character := CharacterData.new()
	character.invulnerability_time = 0.0
	_player = Player.new()
	_player.setup(character, arena)
	_player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(_player)
	_enemies = EnemyManager.new()
	_enemies.setup(_player, arena, 8)
	add_child_autofree(_enemies)
	_wallet = Wallet.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	_effects = ItemEffects.new()
	_effects.setup(_player, _enemies, _wallet, rng)
	add_child_autofree(_effects)


# --- Stats ------------------------------------------------------------------

func test_dodge_is_capped_at_60_percent() -> void:
	_player.stats.set_base(StatIds.DODGE, 5.0)
	assert_almost_eq(_player.stats.get_value(StatIds.DODGE), 0.6, 0.0001)


func test_dodge_avoids_part_of_the_hits() -> void:
	_player.rng.seed = 11
	_player.stats.set_base(StatIds.DODGE, 0.5)
	_player.stats.set_base(StatIds.MAX_HP, 100000.0)
	_player.hp = 100000.0
	var hits: Array[int] = [0]  # lambdas capture locals by value
	_player.damaged.connect(func(_amount: float) -> void: hits[0] += 1)
	for i in 200:
		_player.take_damage(1.0)
	assert_between(hits[0], 70, 130, "about half the hits land")


func test_lifesteal_heals_and_is_capped_per_second() -> void:
	_player.stats.set_base(StatIds.LIFESTEAL, 1.0)
	_player.hp = 50.0
	for i in 50:
		_enemies.enemy_damaged.emit(Vector2.ZERO, 5.0, false)
	assert_eq(_player.hp, 50.0 + ItemEffects.LIFESTEAL_MAX_PER_SECOND, "10 HP/s at most")


func test_harvest_pays_at_wave_end_and_grows() -> void:
	_player.stats.set_base(StatIds.HARVEST, 10.0)
	assert_eq(_effects.on_wave_ended(1), 10)
	assert_eq(_effects.on_wave_ended(11), 15, "+5 % per wave passed")
	assert_eq(_wallet.amount, 25)


func test_luck_raises_shop_tiers() -> void:
	var config := ShopConfig.new()
	var rng := RandomNumberGenerator.new()
	var high_without := 0
	var high_with := 0
	rng.seed = 5
	for i in 2000:
		if config.roll_tier(10, rng, 0.0) > 1:
			high_without += 1
	rng.seed = 5
	for i in 2000:
		if config.roll_tier(10, rng, 100.0) > 1:
			high_with += 1
	assert_gt(high_with, high_without * 1.3, "100 luck = clearly more high tiers")


func test_new_stats_have_localized_names() -> void:
	for stat in [StatIds.DODGE, StatIds.LIFESTEAL, StatIds.LUCK, StatIds.HARVEST]:
		assert_true(StatIds.is_valid(stat))
		assert_ne(tr(StatIds.localization_key(stat)), StatIds.localization_key(stat))
