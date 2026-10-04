class_name BalanceSimTools
## Shared formulas of the balance tools (ADR 0019): build DPS on the sheet and
## enemies one hit reaches in a dense crowd.

## Late-wave crowd: about one enemy per 70 x 70 px.
const CROWD_DENSITY := 1.0 / (70.0 * 70.0)
const MAX_TARGETS := 10.0  # = EnemyManager.area_max_targets


## Damage per second written on the weapons (no positioning, no overkill):
## a trend indicator of build power, not a combat result.
static func sheet_dps(weapons: WeaponHolder, stats: StatBlock) -> float:
	var total := 0.0
	var crit := stats.get_value(StatIds.CRIT_CHANCE)
	var crit_mult := stats.get_value(StatIds.CRIT_DAMAGE)
	var count_bonus := stats.get_value(StatIds.PROJECTILE_COUNT)
	for slot in weapons.get_slots():
		var s := slot.stats
		var hits_per_second := stats.get_value(StatIds.ATTACK_SPEED) / maxf(s.cooldown, 0.05)
		var crit_factor := 1.0 + clampf(s.crit_chance + crit, 0.0, 1.0) * (crit_mult - 1.0)
		total += s.damage * stats.get_value(StatIds.DAMAGE) * crit_factor * hits_per_second \
			* maxf(s.projectile_count + count_bonus, 1.0)
	return total


## Enemies one hit reaches in a dense crowd (capped): arc area for melee, beam
## area, strike area, or pierce + bounces + explosion area for projectiles.
static func targets_hit(weapon: WeaponData, s: WeaponStats) -> float:
	var behavior := weapon.behavior
	var reach := 1.0
	if behavior is MeleeArcBehavior:
		reach = PI * s.area * s.area * s.arc_degrees / 360.0 * CROWD_DENSITY
	elif behavior is BeamBehavior:
		reach = s.attack_range * s.area * CROWD_DENSITY
	elif behavior is StrikeBehavior:
		reach = PI * s.area * s.area * CROWD_DENSITY
	else:
		reach = 1.0 + s.pierce + s.bounces + PI * s.explosion_radius * s.explosion_radius * CROWD_DENSITY
	return clampf(reach, 1.0, MAX_TARGETS)
