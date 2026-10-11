class_name WeaponContext
extends RefCounted
## Everything a WeaponBehavior may need, built once per run by run.gd.

var owner: Node2D
var stats: StatBlock
var enemies: EnemyManager
var projectiles: ProjectileManager
var rng: RandomNumberGenerator
## May be null (tests).
var vfx: Vfx
## Player number of the owner: EnemyManager.damage_source while it attacks (ADR 0017).
var source: int = 0


func _init(p_owner: Node2D, p_stats: StatBlock, p_enemies: EnemyManager,
		p_projectiles: ProjectileManager, p_rng: RandomNumberGenerator, p_vfx: Vfx = null) -> void:
	owner = p_owner
	stats = p_stats
	enemies = p_enemies
	projectiles = p_projectiles
	rng = p_rng
	vfx = p_vfx


## The enemy `slot`'s attack aims at: the nearest, or for the 2nd, 3rd... copy of a weapon the 2nd, 3rd... nearest.
func pick_target(slot: WeaponSlot, from: Vector2, max_distance: float) -> int:
	return enemies.find_nth_nearest(from, max_distance, slot.copy_rank)


func roll_crit(weapon: WeaponStats) -> bool:
	return CombatMath.is_crit(weapon.crit_chance + stats.get_value(StatIds.CRIT_CHANCE), rng.randf())


## Damage of one hit of `weapon`, with the owner's damage stats applied.
func hit_damage(weapon: WeaponStats, crit: bool) -> float:
	return CombatMath.outgoing_damage(weapon.damage, stats.get_value(StatIds.DAMAGE),
		crit, stats.get_value(StatIds.CRIT_DAMAGE))


## Where a shot of `slot` aimed along `direction` starts: the weapon's muzzle.
## `target_distance` (from the mount) shortens the barrel at point blank, so the
## shot never starts past its target.
func muzzle(slot: WeaponSlot, direction: Vector2, target_distance: float = INF) -> Vector2:
	var barrel := minf(WeaponLayout.BARREL, target_distance * 0.5)
	return owner.global_position + slot.mount_offset + direction * barrel
