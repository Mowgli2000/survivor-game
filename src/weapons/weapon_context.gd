class_name WeaponContext
extends RefCounted
## Everything a WeaponBehavior may need, built once per run by run.gd.

var owner: Node2D
var stats: StatBlock
var enemies: EnemyManager
var projectiles: ProjectileManager
var rng: RandomNumberGenerator


func _init(p_owner: Node2D, p_stats: StatBlock, p_enemies: EnemyManager,
		p_projectiles: ProjectileManager, p_rng: RandomNumberGenerator) -> void:
	owner = p_owner
	stats = p_stats
	enemies = p_enemies
	projectiles = p_projectiles
	rng = p_rng
