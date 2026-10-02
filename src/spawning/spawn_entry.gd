class_name SpawnEntry
extends Resource
## One enemy type in a run's spawn pool.

@export var enemy: EnemyData
@export var weight: float = 1.0
## Seconds into the run before this enemy can spawn.
@export var min_time: float = 0.0
