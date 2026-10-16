class_name WingBlastPattern
extends BossPattern
## The demon beats its wings and a blast of hot wind and sparks hits both of its sides at once, in two wide
## wedges (shown at the windup). In front of it and behind it are safe, and so is the far distance.

@export var radius: float = 360.0
@export var half_degrees: float = 48.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	for side: float in [-1.0, 1.0]:
		var facing := (aim - boss.position).angle() + PI * 0.5 * side
		for k in 5:
			var angle := facing + deg_to_rad(half_degrees) * (k - 2) * 0.5
			_warn_line(ctx, boss.position, boss.position + Vector2.from_angle(angle) * radius, radius * 0.22, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	for side: float in [-1.0, 1.0]:
		var facing := (aim - boss.position).angle() + PI * 0.5 * side
		_hurt_sector(ctx, boss, boss.position, facing, radius, deg_to_rad(half_degrees))
		_strike_fx(ctx, boss, boss.position + Vector2.from_angle(facing) * radius * 0.5, radius * 0.6, facing)
	_shake(ctx, 0.4)


func validate() -> String:
	return "wing blast too small" if radius <= 0.0 or half_degrees <= 0.0 else super.validate()
