class_name ClubShockwavePattern
extends BossPattern
## The giant slams its club and a wide wave of ice runs straight at the player along a long band (shown at the
## windup). The band is long and thick: step out sideways, early.

@export var wave_length: float = 780.0
@export var half_width: float = 85.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	var end := boss.position + _dir_to(boss.position, aim) * wave_length
	_warn_line(ctx, boss.position, end, half_width * 2.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	var direction := _dir_to(boss.position, aim)
	var end := boss.position + direction * wave_length
	_hurt_segment(ctx, boss, boss.position, end, half_width)
	_strike_fx(ctx, boss, boss.position + direction * wave_length * 0.5, wave_length * 0.5, direction.angle())
	_shake(ctx, 0.45)


func validate() -> String:
	return "wave too small" if wave_length <= 0.0 or half_width <= 0.0 else super.validate()
