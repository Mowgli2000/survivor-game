class_name TailSweepPattern
extends BossPattern
## The dragon whips its tail round in a full circle: a wide band around it, between an inner and an outer
## radius, is hurt (shown at the windup). The ground right against the dragon and the ground far from it are
## both safe: step in under the tail or run out of its reach.

@export var inner: float = 260.0  # the painted ring's hole is 0.65 of its outer radius
@export var outer: float = 400.0


func telegraph(ctx: BossContext, boss: Enemy, _aim: Vector2) -> void:
	if ctx.vfx != null:
		ctx.vfx.warning_ring(boss.position, inner, outer, boss.data.color, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, _aim: Vector2, _repeat: int) -> void:
	_hurt_ring(ctx, boss, boss.position, inner, outer)
	_strike_fx(ctx, boss, boss.position, outer)
	_shake(ctx, 0.4)


func validate() -> String:
	return "tail band needs two radii" if inner < 0.0 or outer <= inner else super.validate()
