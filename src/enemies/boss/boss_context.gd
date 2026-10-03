class_name BossContext
extends RefCounted
## What boss patterns may use (ADR 0014). Built by BossDirector.

var player: Player
var enemies: EnemyManager
var enemy_projectiles: EnemyProjectileManager
## May be null (tests).
var vfx: Vfx
var rng: RandomNumberGenerator
## Current wave HP scaling, for summoned minions.
var hp_multiplier: float = 1.0
