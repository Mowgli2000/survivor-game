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


# --- Item effects -----------------------------------------------------------

func _item(effect: ItemEffect) -> ItemData:
	var item := ItemData.new()
	item.effects = [effect]
	return item


func _enemy(hp: float) -> EnemyData:
	var data := EnemyData.new()
	data.max_hp = hp
	data.speed = 0.0
	return data


func test_explode_on_kill_damages_nearby_enemies_without_chaining_forever() -> void:
	var effect := ExplodeOnKillEffect.new()
	effect.chance = 1.0
	effect.radius = 100.0
	effect.damage = 50.0
	_effects.add_item(_item(effect))
	var near := _enemies.spawn(_enemy(200.0), Vector2(300, 40))
	var far := _enemies.spawn(_enemy(200.0), Vector2(600, 0))
	await wait_physics_frames(1)
	_enemies.enemy_killed.emit(_enemy(1.0), Vector2(300, 0), false)
	assert_almost_eq(near.hp, 150.0, 0.01, "caught in the blast")
	assert_eq(far.hp, 200.0, "out of range")


func test_material_on_kill() -> void:
	var effect := MaterialOnKillEffect.new()
	effect.chance = 1.0
	effect.amount = 2
	_effects.add_item(_item(effect))
	_enemies.enemy_killed.emit(_enemy(1.0), Vector2.ZERO, false)
	_enemies.enemy_killed.emit(_enemy(1.0), Vector2.ZERO, false)
	assert_eq(_wallet.amount, 4)


func test_interest_is_capped() -> void:
	var effect := InterestEffect.new()
	effect.percent = 0.1
	effect.cap = 25
	_effects.add_item(_item(effect))
	_wallet.add(100)
	_effects.on_wave_ended(1)
	assert_eq(_wallet.amount, 110)
	_wallet.add(390)
	_effects.on_wave_ended(2)
	assert_eq(_wallet.amount, 525, "+25 max")


func test_conditional_stat_follows_its_source() -> void:
	var effect := ConditionalStatEffect.new()
	effect.source_stat = StatIds.ARMOR
	effect.step = 1.0
	effect.target_stat = StatIds.DAMAGE
	effect.percent_per_step = 0.01
	_effects.add_item(_item(effect))
	var armor := StatModifier.new()  # armor from items: above the base value
	armor.stat = StatIds.ARMOR
	armor.flat = 10.0
	_player.stats.add_modifier(armor)
	assert_almost_eq(_player.stats.get_value(StatIds.DAMAGE), 1.10, 0.0001)
	_player.stats.remove_modifier(armor)
	armor.flat = 4.0
	_player.stats.add_modifier(armor)
	assert_almost_eq(_player.stats.get_value(StatIds.DAMAGE), 1.04, 0.0001)


func test_conditional_stat_rejects_a_loop() -> void:
	var effect := ConditionalStatEffect.new()
	effect.source_stat = StatIds.DAMAGE
	effect.target_stat = StatIds.DAMAGE
	assert_gt(effect.validate().size(), 0)


func test_kill_stacks_are_per_copy_and_capped() -> void:
	var effect := KillStackEffect.new()
	effect.kills_per_stack = 2
	effect.max_stacks = 3
	var mod := StatModifier.new()
	mod.stat = StatIds.MAX_HP
	mod.flat = 1.0
	effect.modifier = mod
	var item := _item(effect)
	_effects.add_item(item)
	_effects.add_item(item)  # second copy: its own counter
	for i in 10:
		_enemies.enemy_killed.emit(_enemy(1.0), Vector2.ZERO, false)
	assert_eq(_player.stats.get_value(StatIds.MAX_HP), 106.0, "2 copies x 3 stacks max")


func test_periodic_heal() -> void:
	var effect := PeriodicHealEffect.new()
	effect.interval = 1.0
	effect.amount = 3.0
	_effects.add_item(_item(effect))
	_player.hp = 50.0
	_effects.set_physics_process(false)
	for i in 25:
		_effects._physics_process(0.1)
	assert_eq(_player.hp, 56.0, "2 heals in 2.5 s")


func test_owned_unique_item_is_never_offered_again() -> void:
	var unique: ItemData = ContentDB.get_def(&"items", &"chain_reactor")
	assert_eq(unique.max_count, 1)
	var inventory := Inventory.new(_player.stats)
	inventory.add(unique)
	var holder := WeaponHolder.new()
	autofree(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var shop := Shop.new(ShopConfig.new(), Wallet.new(), inventory, holder, [], [unique], rng)
	shop.open(10)
	for offer in shop.offers:
		assert_ne(offer.item, unique)


func test_lifesteal_hook_only_listens_when_the_stat_is_positive() -> void:
	assert_false(_enemies.enemy_damaged.is_connected(_effects._on_enemy_damaged), "no cost per hit by default")
	_player.stats.set_base(StatIds.LIFESTEAL, 0.05)
	assert_true(_enemies.enemy_damaged.is_connected(_effects._on_enemy_damaged))
	_player.stats.set_base(StatIds.LIFESTEAL, 0.0)
	assert_false(_enemies.enemy_damaged.is_connected(_effects._on_enemy_damaged))
