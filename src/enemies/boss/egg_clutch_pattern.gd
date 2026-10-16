class_name EggClutchPattern
extends BossPattern
## The queen lays a clutch of eggs around herself (the spots are shown at the windup); they burst and hurt what
## is next to them, and a larva crawls out of each. Kill them, or stay away from the clutch.

@export var larva: EnemyData
@export var eggs: int = 5
@export var ring: float = 300.0
@export var egg_radius: float = 80.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx == null:
		return
	for k in eggs:
		ctx.vfx.warning_circle(egg(boss, aim, k), egg_radius, boss.data.color, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	for k in eggs:
		var at := egg(boss, aim, k)
		_hurt_circle(ctx, boss, at, egg_radius)
		_strike_fx(ctx, boss, at, egg_radius * 1.5)
		if larva != null:
			ctx.enemies.spawn(larva, at, ctx.hp_multiplier, false, boss.damage_multiplier)
	_shake(ctx, 0.2)


## Egg `k`: on a ring around the boss, the first toward the player.
func egg(boss: Enemy, aim: Vector2, k: int) -> Vector2:
	return boss.position + Vector2.from_angle((aim - boss.position).angle() + TAU * (k + 0.5) / eggs) * ring


func validate() -> String:
	return "egg clutch needs eggs" if eggs < 1 or egg_radius <= 0.0 else super.validate()
