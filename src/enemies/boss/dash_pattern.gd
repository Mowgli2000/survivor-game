class_name DashPattern
extends BossPattern
## Charge in a straight line towards where the player stood when the windup
## began (shown by a warning line). Contact damage does the hurting.

@export var dash_speed: float = 850.0
@export var dash_duration: float = 0.5


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	var direction := _direction(boss, aim)
	_warn_line(ctx, boss.position, boss.position + direction * dash_speed * dash_duration,
		boss.radius * 2.0, boss.data.color)


func fire(_ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	boss.forced_velocity = _direction(boss, aim) * dash_speed
	boss.forced_time = dash_duration


func validate() -> String:
	return "dash too weak" if dash_speed <= 0.0 or dash_duration <= 0.0 else super.validate()


func _direction(boss: Enemy, aim: Vector2) -> Vector2:
	var offset := aim - boss.position
	return offset.normalized() if offset.length_squared() > 1.0 else Vector2.RIGHT
