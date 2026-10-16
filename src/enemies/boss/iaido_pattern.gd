class_name IaidoPattern
extends BossPattern
## One huge draw-cut: a long windup (the whole arc is shown), then a single sweep that hurts
## everything in a wide sector in front of the boss. Be behind it, or out of reach.

@export var radius: float = 380.0
@export var half_degrees: float = 105.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	var facing := (aim - boss.position).angle()
	var half := deg_to_rad(half_degrees)
	var lines := 13
	for k in lines:
		var angle := facing - half + 2.0 * half * k / (lines - 1)
		_warn_line(ctx, boss.position, boss.position + Vector2.from_angle(angle) * radius, radius * 0.3, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	var facing := (aim - boss.position).angle()
	var half := deg_to_rad(half_degrees)
	_hurt_sector(ctx, boss, boss.position, facing, radius, half)
	for k in 7:
		var angle := facing - half + 2.0 * half * k / 6.0
		_strike_fx(ctx, boss, boss.position + Vector2.from_angle(angle) * radius * 0.7, radius * 0.45)
	_shake(ctx, 0.5)


func validate() -> String:
	return "iaido too small" if radius <= 0.0 or half_degrees <= 0.0 else super.validate()
