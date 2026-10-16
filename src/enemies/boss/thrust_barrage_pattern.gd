class_name ThrustBarragePattern
extends BossPattern
## A chain of lunges: the boss stops and shows where it will go (even volleys), then charges
## there (odd volleys). `repeats` = 2 x number of lunges. Contact damage does the hurting.

@export var dash_speed: float = 1100.0
@export var dash_duration: float = 0.3


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_line(ctx, boss.position, boss.position + _toward(boss, aim) * dash_speed * dash_duration,
		boss.radius * 2.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	if repeat % 2 == 0:
		var target := aim if repeat == 0 else ctx.target_position(boss.position)
		boss.special_dir = _toward(boss, target)
		boss.forced_velocity = Vector2.ZERO
		boss.forced_time = repeat_interval
		if repeat > 0 and ctx.vfx != null:
			ctx.vfx.warning_line(boss.position, boss.position + boss.special_dir * dash_speed * dash_duration,
				boss.radius * 2.0, boss.data.color, repeat_interval)
		return
	boss.forced_velocity = boss.special_dir * dash_speed
	boss.forced_time = dash_duration


func validate() -> String:
	if repeats < 2 or repeats % 2 != 0:
		return "a barrage is pairs of volleys (aim, lunge)"
	return super.validate()


func _toward(boss: Enemy, target: Vector2) -> Vector2:
	var offset := target - boss.position
	return offset.normalized() if offset.length_squared() > 1.0 else Vector2.RIGHT
