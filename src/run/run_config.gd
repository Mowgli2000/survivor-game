class_name RunConfig
extends Resource
## Tuning of a run: character, arena, stage (waves), progression and weapons.

@export var id: StringName
@export var character: CharacterData
@export var arena_size: Vector2 = Vector2(3200, 3200)
## Waves, enemies and difficulty of the run (data/stages/).
@export var stage: StageData

@export_group("Progression")
## XP needed for level n -> n+1 = round(xp_base * n ^ xp_exponent).
@export var xp_base: float = 5.0
@export var xp_exponent: float = 1.35
@export var upgrade_choices: int = 3
@export var max_xp_gems: int = 300

@export_group("Weapons")
@export var max_weapon_slots: int = 6
