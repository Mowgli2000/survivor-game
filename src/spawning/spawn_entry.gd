class_name SpawnEntry
extends Resource
## One enemy type in a stage's spawn pool.

@export var enemy: EnemyData
@export var weight: float = 1.0
## First wave (1-based) where this enemy can spawn.
@export var min_wave: int = 1
