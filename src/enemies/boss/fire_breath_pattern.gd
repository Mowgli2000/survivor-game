class_name FireBreathPattern
extends BossPattern
## The dragon sweeps a long jet of fire across a wide arc in front of it, from one edge to the other over the
## repeats. Each jet is announced just before it burns (the first at the windup, the next ones as the jet
## before them fires), so the warning travels along the arc with the attack. Run along behind the jet, or leave
## the dragon's reach.

@export var length: float = 660.0
@export var jet_half_degrees: float = 24.0
@export var sweep_degrees: float = 90.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_sector(ctx, boss, boss.mouth_position(), jet_angle(boss, aim, 0), length, deg_to_rad(jet_half_degrees))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var angle := jet_angle(boss, aim, repeat)
	var mouth := boss.mouth_position()  # the jet leaves the mouth and follows the dragon if it moves
	_hurt_sector(ctx, boss, mouth, angle, length, deg_to_rad(jet_half_degrees))
	if repeat % 2 == 0:
		_strike_fx(ctx, boss, mouth + Vector2.from_angle(angle) * length * 0.5, length * 0.5, angle)
		_shake(ctx, 0.12)
	if repeat + 1 < repeats:
		_warn_sector(ctx, boss, mouth, jet_angle(boss, aim, repeat + 1), length, deg_to_rad(jet_half_degrees),
				repeat_interval)


## Direction of the jet at volley `repeat`: from one edge of the arc to the other, centered on the player.
func jet_angle(boss: Enemy, aim: Vector2, repeat: int) -> float:
	var t := 0.5 if repeats <= 1 else float(repeat) / (repeats - 1)
	return (aim - boss.mouth_position()).angle() - deg_to_rad(sweep_degrees) * 0.5 + deg_to_rad(sweep_degrees) * t


func validate() -> String:
	return "breath too small" if length <= 0.0 or jet_half_degrees <= 0.0 or repeats < 3 else super.validate()
