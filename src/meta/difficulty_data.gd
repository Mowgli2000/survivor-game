class_name DifficultyData
extends Resource
## A difficulty level, shown as a seal (Copper -> Astral, ADR 0018; "Danger 0-5"
## of step 7b), unlocked per character by winning the level below. Applied to a
## copy of the stage by StageData.with_difficulty(). Instances live in data/difficulties/.

@export var id: StringName
@export var level: int = 0
@export var name_key: String
@export var description_key: String
@export var hp_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var spawn_rate_multiplier: float = 1.0
@export var group_size_bonus: int = 0
## Chance that a steadily spawned enemy is an elite.
@export_range(0.0, 1.0) var steady_elite_chance: float = 0.0
## The final wave's boss event spawns two bosses.
@export var double_final_boss: bool = false
## Where the seal's gate leads: bestiary, bosses and arena (null: the default dungeon).
@export var biome: BiomeData
## Seal and portal color, heat gradient: glacier blue, cyan, emerald, gold, orange, red (the
## seal plaque, the painted portal of the seal screen and the gate the heroes walk out of).
@export var color: Color = Color.WHITE
