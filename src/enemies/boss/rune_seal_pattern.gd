class_name RuneSealPattern
extends BossPattern
## A huge golden rune circle is drawn on the ground around where the player stands at the windup, and
## lights up; when it bursts, everything inside it is hurt. The circle is wide: run out of it.

@export var seal_radius: float = 280.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx != null:
		ctx.vfx.warning_circle(aim, seal_radius, boss.data.color, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	_hurt_circle(ctx, boss, aim, seal_radius)
	_strike_fx(ctx, boss, aim, seal_radius)
	_shake(ctx, 0.4)


func validate() -> String:
	return "seal too small" if seal_radius <= 0.0 else super.validate()
