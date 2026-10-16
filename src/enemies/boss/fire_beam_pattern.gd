class_name FireBeamPattern
extends BossPattern
## A beam of hellfire sweeps around the demon like the hand of a clock: each volley burns one narrow band, one
## step further round than the last (the first band is shown at the windup, then the next one each volley).
## Stay ahead of the beam, or leave its radius.

@export var length: float = 720.0
@export var half_width: float = 55.0
@export var step_degrees: float = 24.0
@export var clockwise: bool = true


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_line(ctx, boss.position, boss.position + Vector2.from_angle(beam_angle(boss, aim, 0)) * length, half_width * 2.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var angle := beam_angle(boss, aim, repeat)
	var tip := boss.position + Vector2.from_angle(angle) * length
	_hurt_segment(ctx, boss, boss.position, tip, half_width)
	_strike_fx(ctx, boss, boss.position.lerp(tip, 0.5), length * 0.5, angle)
	if repeat + 1 < repeats and ctx.vfx != null:
		var next := boss.position + Vector2.from_angle(beam_angle(boss, aim, repeat + 1)) * length
		ctx.vfx.warning_line(boss.position, next, half_width * 2.0, boss.data.color, repeat_interval)
	if repeat % 4 == 0:
		_shake(ctx, 0.1)


## Angle of the beam at volley `repeat`: it starts two steps behind the player's direction and turns by
## `step_degrees` each volley.
func beam_angle(boss: Enemy, aim: Vector2, repeat: int) -> float:
	var turn_sign := 1.0 if clockwise else -1.0
	return (aim - boss.position).angle() + deg_to_rad(step_degrees) * turn_sign * (repeat - 2)


func validate() -> String:
	return "beam too small" if length <= 0.0 or half_width <= 0.0 or repeats < 3 else super.validate()
