class_name FlameCheckerPattern
extends BossPattern
## Columns of flame erupt on a ring around the player's position in two waves, like the squares of a
## chessboard: first the spots at even places of the ring (shown at the windup), then the ones in between
## (shown one interval before). The safe spot of the first wave is the deadly one of the second.

@export var spots: int = 6
@export var ring_radius: float = 230.0
@export var column_radius: float = 95.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx == null:
		return
	for k in spots:
		ctx.vfx.warning_circle(spot(aim, 0, k), column_radius, boss.data.color, scaled_windup(ctx))
	ctx.vfx.warning_circle(aim, column_radius * 0.9, boss.data.color, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	for k in spots:
		var at := spot(aim, repeat, k)
		_hurt_circle(ctx, boss, at, column_radius)
		_strike_fx(ctx, boss, at, column_radius)
	if repeat == 0:
		_hurt_circle(ctx, boss, aim, column_radius * 0.9)
		_strike_fx(ctx, boss, aim, column_radius * 0.9)
	_shake(ctx, 0.25)
	if repeat + 1 < repeats and ctx.vfx != null:
		for k in spots:
			ctx.vfx.warning_circle(spot(aim, repeat + 1, k), column_radius, boss.data.color, repeat_interval)


## Spot `k` of wave `wave`: the ring, turned by half a step on odd waves.
func spot(aim: Vector2, wave: int, k: int) -> Vector2:
	return aim + Vector2.from_angle(TAU * (k + 0.5 * (wave % 2)) / spots) * ring_radius


func validate() -> String:
	return "checker needs spots" if spots < 3 or column_radius <= 0.0 or repeats < 2 else super.validate()
