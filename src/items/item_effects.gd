class_name ItemEffects
extends Node
## Run system for everything items do beyond plain stat modifiers (ADR 0012):
## - stat-driven rules: lifesteal (on damage dealt) and harvest (at wave end);
## - item effects: each owned copy of an item gets its own ItemEffect instance,
##   which receives the run events (acquired, enemy killed, wave ended, tick).
## Reacts to existing signals only: nothing is added to the per-enemy loops.

const LIFESTEAL_MAX_PER_SECOND := 10.0
## Harvest grows by this fraction per wave already played.
const HARVEST_GROWTH := 0.05

var player: Player
var stats: StatBlock
var enemies: EnemyManager
var wallet: Wallet
var rng: RandomNumberGenerator
## May be null (tests).
var vfx: Vfx

var _effects: Array[ItemEffect] = []
var _heal_budget: float = LIFESTEAL_MAX_PER_SECOND


func setup(p_player: Player, p_enemies: EnemyManager, p_wallet: Wallet, p_rng: RandomNumberGenerator,
		p_vfx: Vfx = null) -> void:
	player = p_player
	stats = p_player.stats
	enemies = p_enemies
	wallet = p_wallet
	rng = p_rng
	vfx = p_vfx
	enemies.enemy_damaged.connect(_on_enemy_damaged)
	enemies.enemy_killed.connect(_on_enemy_killed)


## True with probability `chance`, raised by the luck stat.
func roll(chance: float) -> bool:
	return rng.randf() < chance * maxf(1.0 + stats.get_value(StatIds.LUCK) / 100.0, 0.0)


## One more copy of `item` owned: its effects start working.
func add_item(item: ItemData) -> void:
	for effect in item.effects:
		if effect == null:
			continue
		var instance := effect.duplicate(true) as ItemEffect
		_effects.append(instance)
		instance.on_acquired(self)


func effect_count() -> int:
	return _effects.size()


## End of a wave: harvest and wave-end effects. Returns the harvested materials.
func on_wave_ended(wave: int) -> int:
	var harvest := roundi(stats.get_value(StatIds.HARVEST) * (1.0 + HARVEST_GROWTH * maxi(wave - 1, 0)))
	if harvest > 0:
		wallet.add(harvest)
	for effect in _effects:
		effect.on_wave_ended(self, wave)
	return harvest


func _physics_process(delta: float) -> void:
	_heal_budget = minf(_heal_budget + LIFESTEAL_MAX_PER_SECOND * delta, LIFESTEAL_MAX_PER_SECOND)
	for effect in _effects:
		effect.on_tick(self, delta)


func _on_enemy_damaged(_pos: Vector2, _amount: float, _crit: bool) -> void:
	if _heal_budget < 1.0:
		return
	var lifesteal := stats.get_value(StatIds.LIFESTEAL)
	if lifesteal > 0.0 and rng.randf() < lifesteal:
		_heal_budget -= 1.0
		player.heal(1.0)


func _on_enemy_killed(data: EnemyData, pos: Vector2, elite: bool) -> void:
	for effect in _effects:
		effect.on_enemy_killed(self, data, pos, elite)
