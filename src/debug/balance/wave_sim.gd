class_name WaveSim
extends RefCounted
## Fast balance simulator (ADR 0019): a whole run in milliseconds. Combat is
## replaced by a per-wave calculation; everything else is the real game code
## (stage curves and difficulty, StatBlock, WeaponHolder merges, WeaponFamilies,
## Inventory, Wallet, Progression level-up cards, Shop prices / rerolls / tiers,
## BalancePolicy). Calibrated on real headless runs (balance_sim.tscn):
##   reachable     = share of the wave's enemies that arrive before the timer ends
##                   (they spawn off screen: travel time = spawn distance / speed);
##   kill capacity = K_KILL x sum(weapon DPS x enemies reached) x wave duration;
##   kill ratio    = reachable x min(1, capacity / reachable HP);
##   pressure      = reachable HP / capacity (> 1: overwhelmed);
##   crowd         = enemies alive on average (the unkilled ones pile up, capped
##                   like the game at max_enemies), in units of ALIVE_REF;
##   hits taken/s  = F_HIT x max(crowd - SLACK, 0) ^ P_EXP: a player outruns
##                   enemies until the arena fills up (armor, dodge, regen and
##                   lifesteal applied); the run ends when a wave costs all the HP.
## Character and item effects are approximated (see _effect_*).

## Calibration defaults; balance_fast.gd sets the calibrated values.
var k_kill: float = 0.35
var k_area: float = 0.6
var f_hit: float = 1.2
var p_exp: float = 2.0
const P_CAP := 4.0
## Alive enemies at which kiting gets hard, and the share of it below which the
## player is never hit (outruns them freely).
const ALIVE_REF := 150.0
const SLACK := 0.5
## Capacity noise between waves and runs (log-normal sigma).
const NOISE := 0.12
const MISSING_HP_AVERAGE := 0.3

var character: CharacterData
var stage: StageData
var config: RunConfig
var policy: BalancePolicy
var rng := RandomNumberGenerator.new()
var stats: StatBlock
var weapons: WeaponHolder
var families: WeaponFamilies
var inventory: Inventory
var wallet := Wallet.new()
var progression: Progression
var shop: Shop
var _shop_config: ShopConfig
var _upgrades: Array[UpgradeData] = []
## Effect-driven extra modifiers recomputed each wave (Mage, Archer, Berserker...).
var _dynamic: Array[StatModifier] = []
var _kills_total: int = 0


## `overrides` (balance search, never saved): hp_last, dmg_last, mat_last (late
## end of the curves, re-shaped so that wave PIVOT_WAVE keeps its value),
## late_price (ShopConfig.late_price_growth_per_wave), seal_scale (seal HP /
## damage / spawn bonuses x this).
func setup(p_character: CharacterData, weapon: WeaponData, difficulty: DifficultyData, policy_kind: String,
		seed: int, p_config: RunConfig, overrides: Dictionary = {}) -> void:
	character = p_character
	config = p_config
	rng.seed = seed
	policy = BalancePolicy.new(policy_kind, seed)
	var base := apply_overrides(config.stage.copy(), overrides)
	stage = base.with_difficulty(scaled_difficulty(difficulty, overrides.get("seal_scale", 1.0)))
	stats = StatBlock.from_defaults()
	weapons = WeaponHolder.new()
	weapons.max_slots = config.max_weapon_slots
	weapons.favored_family = character.favored_family
	weapons.off_family_scale = character.off_family_damage_scale
	families = WeaponFamilies.new()
	var family_defs: Array[FamilyData] = []
	family_defs.assign(ContentDB.get_all(&"families"))
	families.setup(weapons, stats, family_defs)
	inventory = Inventory.new(stats)
	progression = Progression.new(config.xp_base, config.xp_exponent)
	var shop_config: ShopConfig = config.shop if config.shop != null else ContentDB.get_def(&"shop", &"default")
	if overrides.has("late_price"):
		shop_config = shop_config.duplicate() as ShopConfig
		shop_config.late_price_growth_per_wave = overrides.late_price
	_shop_config = shop_config
	var weapon_pool: Array[WeaponData] = []
	weapon_pool.assign(ContentDB.get_all(&"weapons").filter(character.allows_weapon))
	var item_pool: Array[ItemData] = []
	item_pool.assign(ContentDB.get_all(&"items"))
	shop = Shop.new(shop_config, wallet, inventory, weapons, weapon_pool, item_pool, rng)
	shop.price_multiplier = character.shop_price_multiplier
	shop.reroll_multiplier = character.reroll_cost_multiplier
	shop.luck_stats = stats
	_upgrades.assign(ContentDB.get_all(&"upgrades"))
	for mod in character.modifiers:
		stats.add_modifier(mod)
	wallet.add(shop_config.starting_materials)
	weapons.add_weapon(weapon)


## Wave whose values the late-curve overrides keep (the dev likes waves 1-10).
const PIVOT_WAVE := 10


static func apply_overrides(stage: StageData, overrides: Dictionary) -> StageData:
	var t := stage.t_at(PIVOT_WAVE)
	if overrides.has("hp_last"):
		var pivot := stage.hp_multiplier_at(PIVOT_WAVE)
		stage.hp_multiplier_last = overrides.hp_last
		stage.hp_multiplier_curve = _curve_through(stage.hp_multiplier_first, stage.hp_multiplier_last, t, pivot)
	if overrides.has("dmg_last"):
		var pivot := stage.damage_multiplier_at(PIVOT_WAVE)
		stage.damage_multiplier_last = overrides.dmg_last
		stage.damage_multiplier_curve = _curve_through(stage.damage_multiplier_first, stage.damage_multiplier_last, t, pivot)
	if overrides.has("mat_last"):
		var pivot := lerpf(stage.material_rate_first, stage.material_rate_last, pow(t, stage.material_rate_curve))
		stage.material_rate_last = overrides.mat_last
		stage.material_rate_curve = _curve_through(stage.material_rate_first, stage.material_rate_last, t, pivot)
	return stage


## Exponent x such that lerp(first, last, t^x) == value (keeps the pivot wave).
static func _curve_through(first: float, last: float, t: float, value: float) -> float:
	var ratio := (value - first) / (last - first) if not is_equal_approx(last, first) else 1.0
	if ratio <= 0.0 or ratio >= 1.0 or t <= 0.0 or t >= 1.0:
		return 1.0
	return log(ratio) / log(t)


static func scaled_difficulty(difficulty: DifficultyData, scale: float) -> DifficultyData:
	if is_equal_approx(scale, 1.0):
		return difficulty
	var dup := difficulty.duplicate() as DifficultyData
	dup.hp_multiplier = 1.0 + (difficulty.hp_multiplier - 1.0) * scale
	dup.damage_multiplier = 1.0 + (difficulty.damage_multiplier - 1.0) * scale
	dup.spawn_rate_multiplier = 1.0 + (difficulty.spawn_rate_multiplier - 1.0) * scale
	return dup


## Plays the whole run; returns the same report shape as balance_sim.gd.
func play() -> Dictionary:
	var waves := []
	var outcome := "won"
	for wave in range(1, stage.wave_count + 1):
		var w := _play_wave(wave)
		waves.append(w)
		if w.died:
			outcome = "died"
			break
		if wave < stage.wave_count:
			var before := wallet.amount
			shop.open(wave)
			policy.play_shop(shop, wallet, weapons, wave)
			w["spent"] = before - wallet.amount
			w["materials_after_shop"] = wallet.amount
	weapons.free()
	return {"character": String(character.id), "outcome": outcome, "won": outcome == "won",
		"wave_reached": waves.size(), "waves": waves, "items": _item_list(), "real_seconds": 0.0}


func _play_wave(wave: int) -> Dictionary:
	_apply_effects()
	var duration := stage.duration_at(wave)
	var enemy := _wave_enemies(wave)
	var reach: float = clampf(1.0 - enemy.travel / duration, 0.15, 1.0)
	var hp_total: float = enemy.hp_total * reach
	var noise := exp(rng.randfn(0.0, NOISE))
	# Two passes: how many enemies an area weapon reaches depends on the pressure.
	var pressure := 1.0
	var capacity := 0.0
	for pass_index in 2:
		capacity = k_kill * crowd_dps(clampf(pressure, 0.2, 1.0)) * duration * noise
		pressure = hp_total / maxf(capacity, 1.0)
	var kill_ratio := reach * clampf(capacity / maxf(hp_total, 1.0), 0.0, 1.0)
	var kills := roundi(enemy.count * kill_ratio)
	_kills_total += kills
	var xp := roundi(enemy.xp_per_enemy * kills)
	progression.add_xp(xp)
	wallet.add_scaled(xp, stage.material_rate_at(wave))
	_effect_on_kills(kills)
	# Damage taken over the wave.
	# Only enemies that reached the player and survived threaten him; the ones
	# still on their way when the timer ends are far away and vanish.
	var unkilled: float = enemy.count * (reach - kill_ratio)
	var alive: float = minf(unkilled * 0.5 + enemy.count * 0.02, float(stage.max_enemies))
	var hits := f_hit * pow(clampf(alive / ALIVE_REF - SLACK, 0.0, P_CAP), p_exp) * duration
	var hit: float = enemy.hit_damage * stage.damage_multiplier_at(wave)
	var raw := hits * CombatMath.apply_armor(hit, stats.get_value(StatIds.ARMOR)) \
		* (1.0 - clampf(stats.get_value(StatIds.DODGE), 0.0, 0.6))
	var heal := stats.get_value(StatIds.HP_REGEN) * duration + _lifesteal_heal(duration) + _periodic_heal(duration)
	var max_hp := stats.get_value(StatIds.MAX_HP)
	var taken := maxf(raw - heal, 0.0)
	var died := taken >= max_hp
	# End of wave: level-up cards (real offers), harvest, interest.
	while progression.pending_level_ups > 0 and not died:
		var offers := progression.roll_offers(_upgrades, config.upgrade_choices, rng, _shop_config, wave,
			stats.get_value(StatIds.LUCK))
		if offers.is_empty():
			progression.pending_level_ups = 0
			break
		for offer in offers:
			offer.bonus_scale = character.upgrade_scale
		progression.apply_offer(policy.choose_upgrade(offers, null), stats)
	if not died:
		wallet.add(roundi(stats.get_value(StatIds.HARVEST) * (1.0 + ItemEffects.HARVEST_GROWTH * maxi(wave - 1, 0))))
		_effect_interest()
	policy.last_wave_damage_ratio = taken / maxf(max_hp, 1.0)
	return {
		"wave": wave, "spawned": enemy.count, "kills": kills, "kill_ratio": kill_ratio,
		"damage_taken": taken, "damage_ratio": taken / maxf(max_hp, 1.0), "min_hp_ratio": maxf(1.0 - taken / maxf(max_hp, 1.0), 0.0),
		"level": progression.level, "materials": wallet.amount, "weapons": _weapon_list(),
		"items": inventory.get_items().size(), "sheet_dps": BalanceSimTools.sheet_dps(weapons, stats),
		"max_hp": max_hp, "pressure": pressure, "alive": alive, "died": died,
	}


## Damage per second of the build in a crowd: each weapon's sheet DPS times the
## enemies one hit reaches (area part scaled by K_AREA and the crowd fill 0..1).
func crowd_dps(fill: float) -> float:
	var total := 0.0
	var crit := stats.get_value(StatIds.CRIT_CHANCE)
	var crit_mult := stats.get_value(StatIds.CRIT_DAMAGE)
	var count_bonus := stats.get_value(StatIds.PROJECTILE_COUNT)
	for slot in weapons.get_slots():
		var s := _effective_stats(slot)
		var hits_per_second := stats.get_value(StatIds.ATTACK_SPEED) / maxf(s.cooldown, 0.05)
		var crit_factor := 1.0 + clampf(s.crit_chance + crit, 0.0, 1.0) * (crit_mult - 1.0)
		var dps := s.damage * stats.get_value(StatIds.DAMAGE) * crit_factor * hits_per_second \
			* maxf(s.projectile_count + count_bonus, 1.0)
		var reach := BalanceSimTools.targets_hit(slot.data, s)
		total += dps * (1.0 + (reach - 1.0) * k_area * fill)
	return total


## Weapon stats with the player's area / pierce bonuses (what targets_hit needs).
func _effective_stats(slot: WeaponSlot) -> WeaponStats:
	var s := slot.stats
	var copy := WeaponStats.new()
	copy.damage = s.damage
	copy.cooldown = s.cooldown
	copy.crit_chance = s.crit_chance
	copy.projectile_count = s.projectile_count
	copy.pierce = s.pierce + int(stats.get_value(StatIds.PIERCE))
	copy.bounces = s.bounces
	copy.attack_range = s.attack_range * stats.get_value(StatIds.RANGE)
	copy.area = s.area * stats.get_value(StatIds.AREA)
	copy.explosion_radius = s.explosion_radius * stats.get_value(StatIds.AREA)
	copy.arc_degrees = s.arc_degrees
	return copy


## Enemies of `wave`: count, total HP (steady spawns + events), XP and hit damage
## per enemy, from the stage's spawn pool weights.
func _wave_enemies(wave: int) -> Dictionary:
	var hp_mult := stage.hp_multiplier_at(wave)
	var elite := stage.steady_elite_chance_at(wave)
	var weight := 0.0
	var hp := 0.0
	var xp := 0.0
	var hit := 0.0
	var speed := 0.0
	for entry in stage.spawn_pool:
		if entry.min_wave > wave or entry.enemy == null:
			continue
		var e := entry.enemy
		weight += entry.weight
		hp += entry.weight * e.max_hp * (1.0 + elite * (stage.elite_hp_multiplier - 1.0))
		xp += entry.weight * e.xp_value * (1.0 + elite * (stage.elite_xp_multiplier - 1.0))
		speed += entry.weight * maxf(e.speed, 20.0)
		hit += entry.weight * maxf(e.contact_damage, e.projectile_damage if e.movement == EnemyData.Movement.RANGED else 0.0)
	weight = maxf(weight, 0.001)
	var count := stage.spawn_rate_at(wave) * stage.duration_at(wave)
	var hp_total := count * hp / weight * hp_mult
	var extra_count := 0
	for event in stage.events_for(wave):
		var e: EnemyData = event.enemy if event.enemy != null else (event.enemy_choices[0] if not event.enemy_choices.is_empty() else null)
		if e == null:
			continue
		hp_total += e.max_hp * event.count * hp_mult * (stage.elite_hp_multiplier if event.elite else 1.0)
		extra_count += event.count
	return {"count": roundi(count) + extra_count, "hp_total": hp_total, "xp_per_enemy": xp / weight,
		"hit_damage": hit / weight, "travel": stage.spawn_distance / (speed / weight)}


func _lifesteal_heal(duration: float) -> float:
	var hits := 0.0
	for slot in weapons.get_slots():
		hits += stats.get_value(StatIds.ATTACK_SPEED) / maxf(slot.stats.cooldown, 0.05)
	return minf(stats.get_value(StatIds.LIFESTEAL) * hits, ItemEffects.LIFESTEAL_MAX_PER_SECOND) * duration


# --- Character and item effects (approximations) ---

func _all_effects() -> Array[ItemEffect]:
	var list: Array[ItemEffect] = []
	list.append_array(character.effects)
	for item in inventory.get_items():
		for i in inventory.count(item):
			list.append_array(item.effects)
	return list


## Stat-shaped effects, recomputed at the start of each wave.
func _apply_effects() -> void:
	for mod in _dynamic:
		stats.remove_modifier(mod)
	_dynamic.clear()
	for effect in _all_effects():
		var mod := StatModifier.new()
		if effect is FamilyCountStatEffect:
			var e := effect as FamilyCountStatEffect
			mod.stat = e.modifier.stat
			mod.flat = e.modifier.flat * families.count(e.family)
			mod.percent = e.modifier.percent * families.count(e.family)
		elif effect is MissingHpStatEffect:
			var e := effect as MissingHpStatEffect
			mod.stat = e.target_stat
			mod.percent = e.percent_per_point * MISSING_HP_AVERAGE * 100.0
		elif effect is ConditionalStatEffect:
			var e := effect as ConditionalStatEffect
			var bonus: float = stats.get_value(e.source_stat) - StatIds.DEFAULTS.get(e.source_stat, 0.0)
			var steps := floorf(bonus / maxf(e.step, 0.0001))
			mod.stat = e.target_stat
			mod.percent = e.percent_per_step * steps
			mod.flat = e.flat_per_step * steps
		elif effect is DodgeBuffEffect:
			var e := effect as DodgeBuffEffect
			var uptime := clampf(stats.get_value(StatIds.DODGE) * e.duration, 0.0, 1.0)
			mod.stat = e.modifier.stat
			mod.flat = e.modifier.flat * uptime
			mod.percent = e.modifier.percent * uptime
		elif effect is KillStackEffect:
			var e := effect as KillStackEffect
			var stacks := mini(_kills_total / maxi(e.kills_per_stack, 1), e.max_stacks)
			mod.stat = e.modifier.stat
			mod.flat = e.modifier.flat * stacks
			mod.percent = e.modifier.percent * stacks
		elif effect is ExplodeOnKillEffect:
			# Extra area damage on kills: about chance x half a weapon hit, as damage.
			mod.stat = StatIds.DAMAGE
			mod.percent = (effect as ExplodeOnKillEffect).chance * 0.5
		else:
			continue
		stats.add_modifier(mod)
		_dynamic.append(mod)


func _effect_on_kills(kills: int) -> void:
	for effect in _all_effects():
		if effect is MaterialOnKillEffect:
			var e := effect as MaterialOnKillEffect
			wallet.add(roundi(kills * e.chance * e.amount))


func _effect_interest() -> void:
	for effect in _all_effects():
		if effect is InterestEffect:
			var e := effect as InterestEffect
			wallet.add(mini(floori(wallet.amount * e.percent), e.cap))


func _periodic_heal(duration: float) -> float:
	var heal := 0.0
	for effect in _all_effects():
		if effect is PeriodicHealEffect:
			var e := effect as PeriodicHealEffect
			heal += e.amount * duration / maxf(e.interval, 0.1)
	return heal


func _weapon_list() -> Array:
	var list := []
	for slot in weapons.get_slots():
		list.append("%s:%d" % [slot.data.id, slot.level])
	return list


func _item_list() -> Array:
	var list := []
	for item in inventory.get_items():
		list.append("%s:%d" % [item.id, inventory.count(item)])
	return list
