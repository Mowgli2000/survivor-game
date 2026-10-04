class_name SummonPattern
extends BossPattern
## Calls `count` enemies of type `enemy` in a ring around the boss (or around
## the player's position at the windup: hatching larvae), with the wave's HP
## and damage scaling.

@export var enemy: EnemyData
@export var count: int = 6
@export var distance: float = 110.0
## Ring around the player's position at the windup instead of the boss.
@export var around_target: bool = false


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if not around_target:
		_warn_circle(ctx, boss, distance + 20.0)
	elif ctx.vfx != null and windup > 0.0:
		ctx.vfx.warning_circle(aim, distance + 20.0, boss.data.color, windup)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	var center := aim if around_target else boss.position
	for k in count:
		var pos := center + Vector2.from_angle(TAU * k / count) * distance
		ctx.enemies.spawn(enemy, pos, ctx.hp_multiplier, false, boss.damage_multiplier)


func validate() -> String:
	if enemy == null or count < 1:
		return "summon needs an enemy and a count"
	return super.validate()
