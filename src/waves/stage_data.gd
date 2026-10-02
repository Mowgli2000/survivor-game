class_name StageData
extends Resource
## A stage: a fixed number of timed waves. Wave values are interpolated
## linearly from the first to the last wave; `events` add scripted spawns.
## Instances live in data/stages/.

@export var id: StringName
@export var wave_count: int = 20

@export_group("Curves (wave 1 -> last wave)")
## Wave duration in seconds.
@export var duration_first: float = 20.0
@export var duration_last: float = 60.0
## Enemies per second.
@export var spawn_rate_first: float = 1.5
@export var spawn_rate_last: float = 20.0
@export var hp_multiplier_first: float = 1.0
@export var hp_multiplier_last: float = 5.0

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
	return lerpf(duration_first, duration_last, t_at(wave))


func spawn_rate_at(wave: int) -> float:
	return lerpf(spawn_rate_first, spawn_rate_last, t_at(wave))


func hp_multiplier_at(wave: int) -> float:
	return lerpf(hp_multiplier_first, hp_multiplier_last, t_at(wave))


func events_for(wave: int) -> Array[WaveEvent]:
	var result: Array[WaveEvent] = []
	for event in events:
		if event != null and event.wave == wave:
			result.append(event)
	return result
