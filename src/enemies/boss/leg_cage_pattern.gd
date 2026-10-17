class_name LegCagePattern
extends BossPattern
## Legs stab down in a ring around the player (the eight spots are shown at the windup) and then in the middle
## of the ring (shown during the first stab): the player who stood still is hit by the second stab, the one who
## ran into the ring's gaps is not.

@export var stabs: int = 8
@export var ring_radius: float = 240.0
@export var stab_radius: float = 70.0
@export var center_radius: float = 150.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx == null:
		return
	for k in stabs:
		ctx.vfx.warning_circle(spot(aim, k), stab_radius, boss.data.color, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	if repeat == 0:
		for k in stabs:
			_hurt_circle(ctx, boss, spot(aim, k), stab_radius)
			_strike_fx(ctx, boss, spot(aim, k), stab_radius)
		if ctx.vfx != null:
			ctx.vfx.warning_circle(aim, center_radius, boss.data.color, repeat_interval)  # then the middle
	else:
		_hurt_circle(ctx, boss, aim, center_radius)
		_strike_fx(ctx, boss, aim, center_radius)
	_shake(ctx, 0.25)


func spot(aim: Vector2, k: int) -> Vector2:
	return aim + Vector2.from_angle(TAU * k / stabs) * ring_radius


func validate() -> String:
	return "a leg cage has two volleys (ring, middle)" if repeats != 2 or stabs < 3 else super.validate()
