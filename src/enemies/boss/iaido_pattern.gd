class_name IaidoPattern
extends BossPattern
## One huge draw-cut: a long windup (the whole arc is shown), then a single sweep that hurts
## everything in a wide sector in front of the boss. Be behind it, or out of reach.

@export var radius: float = 380.0
@export var half_degrees: float = 105.0

## The painted crescent is a band: its hollow near the knight (share of the radius, measured on the sheet) is not hurt.
const HOLLOW := 0.5


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_sector(ctx, boss, boss.position, (aim - boss.position).angle(), radius, deg_to_rad(half_degrees), -1.0, radius * HOLLOW)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	var facing := (aim - boss.position).angle()
	var half := deg_to_rad(half_degrees)
	_hurt_sector(ctx, boss, boss.position, facing, radius, half, radius * HOLLOW)
	if effect != null:
		_strike_fx(ctx, boss, boss.position, radius, facing)  # the painted crescent, centered on the knight
	else:
		for k in 7:
			var angle := facing - half + 2.0 * half * k / 6.0
			_strike_fx(ctx, boss, boss.position + Vector2.from_angle(angle) * radius * 0.7, radius * 0.45)
	_shake(ctx, 0.5)


func validate() -> String:
	return "iaido too small" if radius <= 0.0 or half_degrees <= 0.0 else super.validate()
