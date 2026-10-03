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
## Materials per XP point collected (the XP itself is never reduced).
@export var material_rate_first: float = 1.0
@export var material_rate_last: float = 1.0

@export_group("Spawning")
@export var spawn_pool: Array[SpawnEntry] = []
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


## 0.0 on the first wave, 1.0 on the last one (clamped).
func t_at(wave: int) -> float:
	if wave_count <= 1:
		return 0.0
	return clampf(float(wave - 1) / float(wave_count - 1), 0.0, 1.0)


func duration_at(wave: int) -> float:
	if wave >= wave_count and final_wave_duration > 0.0:
		return final_wave_duration
	var steps := maxi(wave - 1, 0)
	return minf(duration_first + duration_step * steps, maxf(duration_last, duration_first))


func spawn_rate_at(wave: int) -> float:
	return lerpf(spawn_rate_first, spawn_rate_last, pow(t_at(wave), spawn_rate_curve))


func hp_multiplier_at(wave: int) -> float:
	return lerpf(hp_multiplier_first, hp_multiplier_last, pow(t_at(wave), hp_multiplier_curve))


func events_for(wave: int) -> Array[WaveEvent]:
	var result: Array[WaveEvent] = []
	for event in events:
		if event != null and event.wave == wave:
			result.append(event)
	return result


func material_rate_at(wave: int) -> float:
	return lerpf(material_rate_first, material_rate_last, t_at(wave))
