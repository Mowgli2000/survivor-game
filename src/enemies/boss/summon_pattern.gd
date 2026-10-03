class_name SummonPattern
extends BossPattern
## Calls `count` enemies of type `enemy` in a ring around the boss, with the
## wave's HP and damage scaling.

@export var enemy: EnemyData
@export var count: int = 6
@export var distance: float = 110.0


func telegraph(ctx: BossContext, boss: Enemy, _aim: Vector2) -> void:
	_warn_circle(ctx, boss, distance + 20.0)


func fire(ctx: BossContext, boss: Enemy, _aim: Vector2, _repeat: int) -> void:
	for k in count:
		var pos := boss.position + Vector2.from_angle(TAU * k / count) * distance
		ctx.enemies.spawn(enemy, pos, ctx.hp_multiplier, false, boss.damage_multiplier)


func validate() -> String:
	if enemy == null or count < 1:
		return "summon needs an enemy and a count"
	return super.validate()
