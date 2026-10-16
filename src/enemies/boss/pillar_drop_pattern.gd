class_name PillarDropPattern
extends BossPattern
## Stone blocks fall one after the other where the player stands: the first on the spot shown at the windup,
## each next one on the position the player has reached when the last one lands (shown for one interval
## only). Standing still is the one thing that gets you hit; keep moving.

@export var zone_radius: float = 85.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	boss.special_dir = aim
	if ctx.vfx != null:
		ctx.vfx.warning_circle(aim, zone_radius, boss.data.color, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, _aim: Vector2, repeat: int) -> void:
	var at := boss.special_dir
	_hurt_circle(ctx, boss, at, zone_radius)
	_strike_fx(ctx, boss, at, zone_radius * 1.5)
	_shake(ctx, 0.2)
	if repeat + 1 < repeats:
		boss.special_dir = ctx.target_position(boss.position)
		if ctx.vfx != null:
			ctx.vfx.warning_circle(boss.special_dir, zone_radius, boss.data.color, repeat_interval)


func validate() -> String:
	return "pillar zone too small" if zone_radius <= 0.0 else super.validate()
