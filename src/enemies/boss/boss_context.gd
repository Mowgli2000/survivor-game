class_name BossContext
extends RefCounted
## What boss patterns may use (ADR 0014). Built by BossDirector.

var party: Party
var enemies: EnemyManager
var enemy_projectiles: EnemyProjectileManager
## May be null (tests).
var vfx: Vfx
var rng: RandomNumberGenerator
## Current wave HP scaling, for summoned minions.
var hp_multiplier: float = 1.0


## Where a boss at `from` aims: the nearest living player (the group center if none).
func target_position(from: Vector2) -> Vector2:
	var target := party.nearest_alive(from)
	return target.global_position if target != null else party.center()
