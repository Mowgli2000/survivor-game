class_name ItemEffects
extends Node
## Run system for everything items do beyond plain stat modifiers (ADR 0012):
## - stat-driven rules: lifesteal (on damage dealt) and harvest (at wave end);
## - item effects: each owned copy of an item gets its own ItemEffect instance,
##   which receives the run events (acquired, enemy killed, wave ended, tick).
## Reacts to existing signals only: nothing is added to the per-enemy loops.

const LIFESTEAL_MAX_PER_SECOND := 10.0
## Effect explosions resolved per physics frame; queue size limit (extras are dropped).
const MAX_EXPLOSIONS_PER_FRAME := 12
const MAX_QUEUED_EXPLOSIONS := 64
## Harvest grows by this fraction per wave already played.
const HARVEST_GROWTH := 0.05

var player: Player
var stats: StatBlock
var enemies: EnemyManager
var wallet: Wallet
var rng: RandomNumberGenerator
## May be null (tests).
var vfx: Vfx
## Player number (ADR 0017): only this player's hits and kills trigger the effects.
var source: int = 0
## Materials from effects follow the stage's material curve (1 = wave 1 rate):
## kills grow much faster than the economy, so per-kill gains are scaled like XP.
var material_scale: float = 1.0
## True while an effect deals damage: kills it causes do not trigger more effect damage.
var effect_damage_running: bool = false

var _effects: Array[ItemEffect] = []
## Pending effect explosions, 4 floats each: x, y, radius, damage. Queued instead of
## dealt at once: kills happen inside EnemyManager's area-damage loops, whose
## scratch buffers a nested damage_in_radius would overwrite.
var _explosions := PackedFloat32Array()
var _heal_budget: float = LIFESTEAL_MAX_PER_SECOND


func setup(p_player: Player, p_enemies: EnemyManager, p_wallet: Wallet, p_rng: RandomNumberGenerator,
		p_vfx: Vfx = null) -> void:
	player = p_player
	stats = p_player.stats
	source = p_player.index
	enemies = p_enemies
	wallet = p_wallet
	rng = p_rng
	vfx = p_vfx
	enemies.enemy_killed.connect(_on_enemy_killed)
	# Hits fire thousands of times per second: listen only while lifesteal > 0.
	stats.changed.connect(func(stat: StringName) -> void:
		if stat == StatIds.LIFESTEAL:
			_update_lifesteal_hook())
	_update_lifesteal_hook()


## True with probability `chance`, raised by the luck stat.
func roll(chance: float) -> bool:
	return rng.randf() < chance * maxf(1.0 + stats.get_value(StatIds.LUCK) / 100.0, 0.0)


## One more copy of `item` owned: its effects start working.
func add_item(item: ItemData) -> void:
	add_effects(item.effects)


## Copies and starts `effects` (items, character rules).
func add_effects(effects: Array[ItemEffect]) -> void:
	for effect in effects:
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


## Damage around `pos` on the next physics frame (no chain: these kills trigger nothing).
func queue_explosion(pos: Vector2, radius: float, damage: float) -> void:
	if _explosions.size() < MAX_QUEUED_EXPLOSIONS * 4:
		_explosions.append_array([pos.x, pos.y, radius, damage])


func pending_explosions() -> int:
	return _explosions.size() / 4


func _physics_process(delta: float) -> void:
	_resolve_explosions()
	_heal_budget = minf(_heal_budget + LIFESTEAL_MAX_PER_SECOND * delta, LIFESTEAL_MAX_PER_SECOND)
	for effect in _effects:
		effect.on_tick(self, delta)


func _resolve_explosions() -> void:
	var count := mini(_explosions.size() / 4, MAX_EXPLOSIONS_PER_FRAME)
	if count == 0:
		return
	effect_damage_running = true
	enemies.damage_source = source
	for i in count:
		var pos := Vector2(_explosions[i * 4], _explosions[i * 4 + 1])
		var radius := _explosions[i * 4 + 2]
		enemies.damage_in_radius(pos, radius, _explosions[i * 4 + 3], false, 150.0)
		if vfx != null:
			vfx.explosion(pos, radius, ExplodeOnKillEffect.COLOR, false)
	effect_damage_running = false
	_explosions = _explosions.slice(count * 4)


func _update_lifesteal_hook() -> void:
	var active := stats.get_value(StatIds.LIFESTEAL) > 0.0
	if active != enemies.enemy_damaged.is_connected(_on_enemy_damaged):
		if active:
			enemies.enemy_damaged.connect(_on_enemy_damaged)
		else:
			enemies.enemy_damaged.disconnect(_on_enemy_damaged)


func _on_enemy_damaged(_pos: Vector2, _amount: float, _crit: bool) -> void:
	if _heal_budget < 1.0 or enemies.damage_source != source:
		return
	var lifesteal := stats.get_value(StatIds.LIFESTEAL)
	if lifesteal > 0.0 and rng.randf() < lifesteal:
		_heal_budget -= 1.0
		player.heal(1.0)


func _on_enemy_killed(data: EnemyData, pos: Vector2, elite: bool) -> void:
	if enemies.damage_source != source:
		return
	for effect in _effects:
		effect.on_enemy_killed(self, data, pos, elite)
