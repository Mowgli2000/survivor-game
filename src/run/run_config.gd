class_name RunConfig
extends Resource
## Tuning of a run (prototype). Will be split into StageData when waves arrive.

@export var id: StringName
@export var character: CharacterData
@export var arena_size: Vector2 = Vector2(3200, 3200)

@export_group("Spawning")
@export var spawn_pool: Array[SpawnEntry] = []
## Enemies per second at the start of the run.
@export var spawn_rate_start: float = 1.0
## Enemies per second added every minute.
@export var spawn_rate_per_minute: float = 1.0
@export var spawn_rate_max: float = 20.0
@export var max_enemies: int = 400
## Distance from the player where enemies appear (just outside the screen).
@export var spawn_distance: float = 1150.0
@export var enemy_hp_multiplier: float = 1.0
## Enemy HP multiplier added every minute.
@export var enemy_hp_per_minute: float = 0.25

@export_group("Progression")
## XP needed for level n -> n+1 = round(xp_base * n ^ xp_exponent).
@export var xp_base: float = 5.0
@export var xp_exponent: float = 1.35
@export var upgrade_choices: int = 3
@export var max_xp_gems: int = 300
