class_name ShadowStepPattern
extends BossPattern
## The boss vanishes and comes back `landing_distance` from the player (circle shown at the
## windup), then strikes a wide arc at the player (second volley). Step back, or go round.
## Needs `repeats` = 2.

@export var landing_distance: float = 150.0
@export var arc_radius: float = 190.0
@export var arc_half_degrees: float = 80.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx != null:
		ctx.vfx.warning_circle(_landing(ctx, boss, aim), boss.radius * 1.4, boss.data.color, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	if repeat == 0:
		_strike_fx(ctx, boss, boss.position, boss.radius * 3.0)
		boss.position = _landing(ctx, boss, aim)
		_strike_fx(ctx, boss, boss.position, boss.radius * 3.0)
		boss.forced_velocity = Vector2.ZERO
		boss.forced_time = repeat_interval
		if ctx.vfx != null:
			ctx.vfx.warning_circle(boss.position, arc_radius, boss.data.color, repeat_interval)
		return
	var facing := (ctx.target_position(boss.position) - boss.position).angle()
	_hurt_sector(ctx, boss, boss.position, facing, arc_radius, deg_to_rad(arc_half_degrees))
	_strike_fx(ctx, boss, boss.position + Vector2.from_angle(facing) * arc_radius * 0.6, arc_radius * 0.8)
	_shake(ctx, 0.3)


## Where the boss comes back: on the boss's side of the player, inside the arena.
func _landing(ctx: BossContext, boss: Enemy, aim: Vector2) -> Vector2:
	var away := boss.position - aim
	var direction := away.normalized() if away.length_squared() > 1.0 else Vector2.RIGHT
	var spot := aim + direction * landing_distance
	if ctx.enemies != null:
		var arena := ctx.enemies.arena_rect().grow(-boss.radius)
		spot = spot.clamp(arena.position, arena.end)
	return spot


func validate() -> String:
	if repeats != 2:
		return "a shadow step has two volleys (jump, strike)"
	return super.validate()
