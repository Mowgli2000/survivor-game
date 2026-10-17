class_name VenomPoolsPattern
extends BossPattern
## Three pools of acid open around the player's position (shown at the windup) and keep burning everything in
## them, every repeat, while they bubble. The gaps between the pools are the only clean ground.

@export var pools: int = 3
@export var pool_radius: float = 130.0
@export var spread: float = 190.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx == null:
		return
	for k in pools:
		ctx.vfx.warning_circle(pool(boss, aim, k), pool_radius, boss.data.color, scaled_windup(ctx))  # gone once the pools open: the painting shows them


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	for k in pools:
		var at := pool(boss, aim, k)
		_hurt_circle(ctx, boss, at, pool_radius)
		_strike_fx(ctx, boss, at, pool_radius)
	if repeat == 0:
		_shake(ctx, 0.15)


func pool(boss: Enemy, aim: Vector2, k: int) -> Vector2:
	return aim + Vector2.from_angle((aim - boss.position).angle() + TAU * k / pools) * spread


func validate() -> String:
	return "pools need a count and a radius" if pools < 1 or pool_radius <= 0.0 or repeats < 2 else super.validate()
