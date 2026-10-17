class_name ChainLashPattern
extends BossPattern
## Heavy burning chains lash out from the demon one after the other, each along its own line (announced one by
## one, just before it falls): the lashes fan out around the player's direction, so the spot that is safe from
## one is under the next.

@export var lashes: int = 3
@export var fan_degrees: float = 38.0
@export var length: float = 780.0
@export var half_width: float = 38.0

## Share of its frame the painted chain fills (measured on the baked sheet).
const ART_THICKNESS := 0.195


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_lash(ctx, boss, aim, 0, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var angle := lash_angle(boss, aim, repeat)
	var tip := boss.position + Vector2.from_angle(angle) * length
	_hurt_segment(ctx, boss, boss.position, tip, half_width)
	_strike_line(ctx, boss.position, tip, half_width * 2.0, ART_THICKNESS)
	_shake(ctx, 0.2)
	if repeat + 1 < repeats:
		_warn_lash(ctx, boss, aim, repeat + 1, repeat_interval)  # lashes are announced one by one, just before they fall


## Announces lash `k`: centered, then left, then right of the player's direction (one lash per volley).
func _warn_lash(ctx: BossContext, boss: Enemy, aim: Vector2, k: int, seconds: float) -> void:
	if ctx.vfx != null:
		ctx.vfx.warning_line(boss.position, boss.position + Vector2.from_angle(lash_angle(boss, aim, k)) * length, half_width * 2.0,
			boss.data.color, seconds)


func lash_angle(boss: Enemy, aim: Vector2, k: int) -> float:
	var offsets := [0.0, -1.0, 1.0, -2.0, 2.0]
	return (aim - boss.position).angle() + deg_to_rad(fan_degrees) * offsets[k % offsets.size()]


func validate() -> String:
	return "a chain lash has one volley per lash" if lashes < 1 or repeats != lashes or length <= 0.0 else super.validate()
