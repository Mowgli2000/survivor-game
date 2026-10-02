class_name WaveEvent
extends Resource
## A scripted spawn inside one wave of a stage (hordes, elites).

## Wave number (1-based) where this event happens.
@export var wave: int = 1
## Seconds after the start of the wave.
@export var at_time: float = 0.0
@export var enemy: EnemyData
## Enemies spawned at once, in a ring around the player.
@export var count: int = 1
@export var elite: bool = false
