class_name AimedFanPattern
extends BossPattern
## Fan of `count` projectiles spread over `spread_degrees`, aimed at the
## player's current position on each repeat.

@export var count: int = 5
@export var spread_degrees: float = 40.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_line(ctx, boss.position, aim, 6.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, _aim: Vector2, _repeat: int) -> void:
	var base := (ctx.target_position(boss.position) - boss.position).angle()
	if count == 1:
		_shoot(ctx, boss, Vector2.from_angle(base))
		return
	var spread := deg_to_rad(spread_degrees)
	for k in count:
		_shoot(ctx, boss, Vector2.from_angle(base - spread * 0.5 + spread * k / (count - 1)))


func validate() -> String:
	return "count < 1" if count < 1 else super.validate()
