class_name DragonFlybyPattern
extends BossPattern
## The dragon leaps into the air and sweeps across the arena in a straight, very fast pass through the spot the
## player stood at the windup (the long path is shown at the windup). Contact damage does the hurting: stay off
## the path.

@export var speed: float = 1250.0
@export var duration: float = 0.85


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_line(ctx, boss.position, boss.position + _dir_to(boss.position, aim) * speed * duration, boss.radius * 2.4, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	boss.forced_velocity = _dir_to(boss.position, aim) * speed
	boss.forced_time = duration
	_shake(ctx, 0.3)


func validate() -> String:
	return "flyby too weak" if speed <= 0.0 or duration <= 0.0 else super.validate()
