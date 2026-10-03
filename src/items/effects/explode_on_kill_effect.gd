class_name ExplodeOnKillEffect
extends ItemEffect
## Killed enemies may explode, damaging the enemies around them. Kills made by
## these explosions do not trigger new ones (no chain across the whole horde).

const COLOR := Color(1.0, 0.55, 0.2)

@export_range(0.0, 1.0) var chance: float = 0.2
@export var radius: float = 90.0
## Base damage, multiplied by the owner's damage stat.
@export var damage: float = 12.0


func on_enemy_killed(effects: ItemEffects, _data: EnemyData, pos: Vector2, _elite: bool) -> void:
	if effects.effect_damage_running or not effects.roll(chance):
		return
	effects.effect_damage_running = true
	effects.enemies.damage_in_radius(pos, radius, damage * effects.stats.get_value(StatIds.DAMAGE), false, 150.0)
	effects.effect_damage_running = false
	if effects.vfx != null:
		effects.vfx.explosion(pos, radius, COLOR, false)
