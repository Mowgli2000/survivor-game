class_name ChainLashPattern
extends BossPattern
## Heavy burning chains lash out from the demon one after the other, each along its own line (all shown at
## the windup, in the order they fall): the lashes fan out around the player's direction, so the spot that is
## safe from one is under the next.

@export var lashes: int = 3
@export var fan_degrees: float = 38.0
@export var length: float = 780.0
@export var half_width: float = 38.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	for k in lashes:
		if ctx.vfx != null:
			var tip := boss.position + Vector2.from_angle(lash_angle(boss, aim, k)) * length
			ctx.vfx.warning_line(boss.position, tip, half_width * 2.0, boss.data.color, scaled_windup(ctx) + k * repeat_interval)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var angle := lash_angle(boss, aim, repeat)
	var tip := boss.position + Vector2.from_angle(angle) * length
	_hurt_segment(ctx, boss, boss.position, tip, half_width)
	_strike_fx(ctx, boss, boss.position.lerp(tip, 0.5), length * 0.5, angle)
	_shake(ctx, 0.2)


## Lash `k`: centered, then left, then right of the player's direction (one lash per volley).
func lash_angle(boss: Enemy, aim: Vector2, k: int) -> float:
	var offsets := [0.0, -1.0, 1.0, -2.0, 2.0]
	return (aim - boss.position).angle() + deg_to_rad(fan_degrees) * offsets[k % offsets.size()]


func validate() -> String:
	return "a chain lash has one volley per lash" if lashes < 1 or repeats != lashes or length <= 0.0 else super.validate()
