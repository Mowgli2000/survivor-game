class_name FireBeamPattern
extends BossPattern
## A beam of hellfire sweeps around the demon like the hand of a clock: each volley burns one narrow band, one
## step further round than the last. Each band is announced just before it burns (the first at the windup), so
## the warning turns with the beam. Stay ahead of the beam, or leave its radius.

@export var length: float = 720.0
@export var half_width: float = 55.0
@export var step_degrees: float = 15.0
@export var clockwise: bool = true

## Share of its frame the painted beam fills (measured on the baked sheet).
const ART_THICKNESS := 0.28


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_beam(ctx, boss, aim, 0, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var angle := beam_angle(boss, aim, repeat)
	var tip := boss.position + Vector2.from_angle(angle) * length
	_hurt_segment(ctx, boss, boss.position, tip, half_width)
	_strike_line(ctx, boss.position, tip, half_width * 2.0, ART_THICKNESS)
	if repeat % 4 == 0:
		_shake(ctx, 0.1)
	if repeat + 1 < repeats:
		_warn_beam(ctx, boss, aim, repeat + 1, repeat_interval)


## Announces the band of beam `repeat` for `seconds`.
func _warn_beam(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int, seconds: float) -> void:
	if ctx.vfx != null:
		ctx.vfx.warning_line(boss.position, boss.position + Vector2.from_angle(beam_angle(boss, aim, repeat)) * length,
				half_width * 2.0, boss.data.color, seconds)


## Angle of the beam at volley `repeat`: it starts two steps behind the player's direction and turns by
## `step_degrees` each volley.
func beam_angle(boss: Enemy, aim: Vector2, repeat: int) -> float:
	var turn_sign := 1.0 if clockwise else -1.0
	return (aim - boss.position).angle() + deg_to_rad(step_degrees) * turn_sign * (repeat - 2)


func validate() -> String:
	return "beam too small" if length <= 0.0 or half_width <= 0.0 or repeats < 3 else super.validate()
