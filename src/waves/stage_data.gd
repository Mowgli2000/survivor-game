class_name StageData
extends Resource
## A stage: a fixed number of timed waves. Durations grow by a fixed step up to
## a cap, Brotato-style (the last wave can have its own duration); spawn rate
## and HP are interpolated linearly from the first to the last wave.
## `events` add scripted spawns (hordes, elites, bosses).
## Instances live in data/stages/.

@export var id: StringName
@export var wave_count: int = 20

@export_group("Durations")
## Wave 1 duration in seconds; each wave adds `duration_step`, up to `duration_last`.
@export var duration_first: float = 20.0
@export var duration_step: float = 5.0
@export var duration_last: float = 60.0
## Duration of the last wave (boss wave). 0 = same rule as the other waves.
@export var final_wave_duration: float = 0.0

@export_group("Curves (wave 1 -> last wave)")
## Enemies per second.
@export var spawn_rate_first: float = 1.5
@export var spawn_rate_last: float = 20.0
@export var hp_multiplier_first: float = 1.0
@export var hp_multiplier_last: float = 5.0
## > 1: the spawn rate ramps up late (t^curve), 1 = linear.
@export var spawn_rate_curve: float = 1.0
## > 1: enemy HP ramps up late (t^curve), 1 = linear.
@export var hp_multiplier_curve: float = 1.0
## Enemy contact and projectile damage (Brotato-style: standing still gets riskier).
@export var damage_multiplier_first: float = 1.0
@export var damage_multiplier_last: float = 1.0
@export var damage_multiplier_curve: float = 1.0
## Steady spawns arrive in groups of this many enemies (1 = one by one).
@export var group_size_first: int = 1
@export var group_size_last: int = 1
## Materials per XP point collected (the XP itself is never reduced).
@export var material_rate_first: float = 1.0
@export var material_rate_last: float = 1.0
## Above this spawn rate (enemies/s), the material rate shrinks so that more
## enemies do not mean proportionally more materials (anti-snowball).
## 0 = disabled.
@export var material_reference_spawn_rate: float = 0.0
## 0 = materials follow the kill count, 1 = materials per second stay flat
## above the reference spawn rate.
@export_range(0.0, 1.0) var material_decoupling: float = 0.0

@export_group("Spawning")
@export var spawn_pool: Array[SpawnEntry] = []
## Chance that a steadily spawned enemy is an elite (difficulty levels).
@export_range(0.0, 1.0) var steady_elite_chance: float = 0.0
@export var max_enemies: int = 400
## Distance from the player where enemies appear (just outside the screen).
@export var spawn_distance: float = 1150.0

@export_group("Between waves")
## Fraction of max HP restored at the end of each wave (1.0 = full heal).
@export var heal_between_waves: float = 1.0

@export_group("Elites")
@export var elite_hp_multiplier: float = 5.0
@export var elite_xp_multiplier: float = 10.0
## Visual size and collision radius multiplier.
@export var elite_scale: float = 1.6

@export_group("Events")
@export var events: Array[WaveEvent] = []

@export_group("Endless (after the last wave)")
## Per-wave compound growth beyond the last wave.
@export var endless_hp_growth: float = 0.12
@export var endless_damage_growth: float = 0.06
@export var endless_spawn_growth: float = 0.04
## Elite chance added per endless wave (steady spawns), up to endless_elite_max.
@export var endless_elite_growth: float = 0.02
@export_range(0.0, 1.0) var endless_elite_max: float = 0.4
## Materials per XP lose this fraction per endless wave (compound).
@export_range(0.0, 1.0) var endless_material_decay: float = 0.08
## The last wave's events (final boss) come back every this many endless waves.
@export var endless_boss_every: int = 10

## Runtime flag, set on a run's copy only: waves go on after the last one.
var endless: bool = false


## 0.0 on the first wave, 1.0 on the last one (clamped).
func t_at(wave: int) -> float:
	if wave_count <= 1:
		return 0.0
	return clampf(float(wave - 1) / float(wave_count - 1), 0.0, 1.0)


func duration_at(wave: int) -> float:
	if wave == wave_count and final_wave_duration > 0.0:
		return final_wave_duration
	var steps := maxi(wave - 1, 0)
	return minf(duration_first + duration_step * steps, maxf(duration_last, duration_first))


func spawn_rate_at(wave: int) -> float:
	return lerpf(spawn_rate_first, spawn_rate_last, pow(t_at(wave), spawn_rate_curve)) \
		* _endless_factor(wave, endless_spawn_growth)


func hp_multiplier_at(wave: int) -> float:
	return lerpf(hp_multiplier_first, hp_multiplier_last, pow(t_at(wave), hp_multiplier_curve)) \
		* _endless_factor(wave, endless_hp_growth)


func damage_multiplier_at(wave: int) -> float:
	return lerpf(damage_multiplier_first, damage_multiplier_last, pow(t_at(wave), damage_multiplier_curve)) \
		* _endless_factor(wave, endless_damage_growth)


func group_size_at(wave: int) -> int:
	return maxi(1, roundi(lerpf(group_size_first, group_size_last, t_at(wave))))


func events_for(wave: int) -> Array[WaveEvent]:
	if endless and wave > wave_count and endless_boss_every > 0 and (wave - wave_count) % endless_boss_every == 0:
		wave = wave_count
	var result: Array[WaveEvent] = []
	for event in events:
		if event != null and event.wave == wave:
			result.append(event)
	return result


func material_rate_at(wave: int) -> float:
	var rate := lerpf(material_rate_first, material_rate_last, t_at(wave))
	var spawn_rate := spawn_rate_at(wave)
	if material_reference_spawn_rate > 0.0 and spawn_rate > material_reference_spawn_rate:
		rate *= pow(material_reference_spawn_rate / spawn_rate, material_decoupling)
	return rate * _endless_factor(wave, -endless_material_decay)


## Copy for one run: events are copied (difficulty may change them), enemy
## definitions stay shared. The original resource is never modified.
func copy() -> StageData:
	var dup := duplicate(false) as StageData
	var copied: Array[WaveEvent] = []
	for event in events:
		copied.append(event.duplicate() as WaveEvent)
	dup.events = copied
	return dup


## Copy with a difficulty level applied (curves scaled, elites, double boss).
func with_difficulty(difficulty: DifficultyData) -> StageData:
	var dup := copy()
	if difficulty == null:
		return dup
	dup.hp_multiplier_first *= difficulty.hp_multiplier
	dup.hp_multiplier_last *= difficulty.hp_multiplier
	dup.damage_multiplier_first *= difficulty.damage_multiplier
	dup.damage_multiplier_last *= difficulty.damage_multiplier
	dup.spawn_rate_first *= difficulty.spawn_rate_multiplier
	dup.spawn_rate_last *= difficulty.spawn_rate_multiplier
	dup.group_size_first += difficulty.group_size_bonus
	dup.group_size_last += difficulty.group_size_bonus
	dup.steady_elite_chance = maxf(dup.steady_elite_chance, difficulty.steady_elite_chance)
	if difficulty.double_final_boss:
		for event in dup.events:
			if event.wave == wave_count:
				event.count *= 2
	if difficulty.biome != null:
		dup.apply_biome(difficulty.biome)
	return dup


## Swaps every monster and boss for the biome's one in the same role. Call on a copy.
func apply_biome(biome: BiomeData) -> void:
	var pool: Array[SpawnEntry] = []
	for entry in spawn_pool:
		var swapped := entry.duplicate() as SpawnEntry
		swapped.enemy = biome.swap(entry.enemy)
		pool.append(swapped)
	spawn_pool = pool
	for event in events:
		event.enemy = biome.swap(event.enemy)
		var choices: Array[EnemyData] = []
		for choice in event.enemy_choices:
			choices.append(biome.swap(choice))
		event.enemy_choices = choices


## Two players (ADR 0017): more and tougher enemies. Call on a copy only.
func apply_coop(spawn_multiplier: float, hp_multiplier: float) -> void:
	spawn_rate_first *= spawn_multiplier
	spawn_rate_last *= spawn_multiplier
	hp_multiplier_first *= hp_multiplier
	hp_multiplier_last *= hp_multiplier


## 1.0 up to the last wave; compound growth per wave beyond it in endless mode.
func _endless_factor(wave: int, growth: float) -> float:
	if not endless or wave <= wave_count:
		return 1.0
	return pow(1.0 + growth, wave - wave_count)


## Chance that a steady spawn is an elite: difficulty base, growing in endless mode.
func steady_elite_chance_at(wave: int) -> float:
	if not endless or wave <= wave_count:
		return steady_elite_chance
	return minf(steady_elite_chance + endless_elite_growth * (wave - wave_count), endless_elite_max)
