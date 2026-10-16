class_name CrossSlashPattern
extends BossPattern
## Two sword lines cross where the player stood at the windup (shown as two bands); when the
## blades come down everything on the lines is hurt. Step out of the cross.

@export var arm_length: float = 460.0
@export var half_width: float = 45.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	for line in _lines(boss, aim):
		_warn_line(ctx, line[0], line[1], half_width * 2.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	var steps := ceili(arm_length / half_width)
	for line in _lines(boss, aim):
		_hurt_segment(ctx, boss, line[0], line[1], half_width)
		if effect == null:
			for k in steps + 1:
				_strike_fx(ctx, boss, line[0].lerp(line[1], float(k) / steps), half_width * 1.8)
	if effect != null:
		_strike_fx(ctx, boss, aim, arm_length, (aim - boss.position).angle())  # the painted X, turned like the lines
	_shake(ctx, 0.35)


## The two diagonals of the cross, as [from, to] pairs.
func _lines(boss: Enemy, aim: Vector2) -> Array:
	var base := (aim - boss.position).angle() + PI * 0.25
	var result: Array = []
	for k in 2:
		var direction := Vector2.from_angle(base + PI * 0.5 * k) * arm_length
		result.append([aim - direction, aim + direction])
	return result


func validate() -> String:
	return "cross too small" if arm_length <= 0.0 or half_width <= 0.0 else super.validate()
