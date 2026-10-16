class_name CrackRaysPattern
extends BossPattern
## The idol stamps and cracks run out of it like the spokes of a wheel (shown as bands at the windup); when
## they split open everything on a spoke is hurt. Each repeat turns the spokes by half a step, so the safe
## wedges of one volley are the deadly ones of the next: the player has to cross a spoke at the right time.

@export var rays: int = 6
@export var length: float = 620.0
@export var half_width: float = 42.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	for k in rays:
		var angle := ray_angle(boss, aim, 0, k)
		_warn_line(ctx, boss.position, boss.position + Vector2.from_angle(angle) * length, half_width * 2.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	for k in rays:
		var angle := ray_angle(boss, aim, repeat, k)
		var tip := boss.position + Vector2.from_angle(angle) * length
		_hurt_segment(ctx, boss, boss.position, tip, half_width)
		_strike_fx(ctx, boss, boss.position.lerp(tip, 0.5), length * 0.5, angle)
	_shake(ctx, 0.3)
	if repeat + 1 < repeats and ctx.vfx != null:
		for k in rays:  # the next volley's spokes, shown in the gaps
			var next := ray_angle(boss, aim, repeat + 1, k)
			ctx.vfx.warning_line(boss.position, boss.position + Vector2.from_angle(next) * length, half_width * 2.0, boss.data.color, repeat_interval)


## Direction of spoke `k` of volley `repeat`: the first volley points one spoke at the player.
func ray_angle(boss: Enemy, aim: Vector2, repeat: int, k: int) -> float:
	var base := (aim - boss.position).angle()
	return base + TAU * k / rays + (PI / rays) * repeat


func validate() -> String:
	return "crack rays need spokes" if rays < 3 or length <= 0.0 or half_width <= 0.0 else super.validate()
