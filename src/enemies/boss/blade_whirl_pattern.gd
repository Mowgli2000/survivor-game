class_name BladeWhirlPattern
extends BossPattern
## The idol spins its four crescent blades: a ring around it is hurt several times in a row. Stay out of the
## ring until the whirl stops (the ring is shown at the windup).

@export var whirl_radius: float = 230.0


func telegraph(ctx: BossContext, boss: Enemy, _aim: Vector2) -> void:
	_warn_circle(ctx, boss, whirl_radius)


func fire(ctx: BossContext, boss: Enemy, _aim: Vector2, _repeat: int) -> void:
	_hurt_circle(ctx, boss, boss.position, whirl_radius)
	_strike_fx(ctx, boss, boss.position, whirl_radius)
	_shake(ctx, 0.15)


func validate() -> String:
	return "whirl too small" if whirl_radius <= 0.0 else super.validate()
