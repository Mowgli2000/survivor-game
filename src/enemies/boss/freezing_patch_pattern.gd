class_name FreezingPatchPattern
extends BossPattern
## The ground freezes into a wide patch where the player stands (shown at the windup) and keeps hurting
## everything inside it, every repeat, for as long as the cold lasts: leave it and stay out. The warning circle
## only lasts the windup (the frozen ground painted by the strikes takes over).

@export var patch_radius: float = 210.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx != null:
		ctx.vfx.warning_circle(aim, patch_radius, boss.data.color, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	_hurt_circle(ctx, boss, aim, patch_radius)
	_strike_fx(ctx, boss, aim, patch_radius)
	if repeat == 0:
		_shake(ctx, 0.2)


func validate() -> String:
	return "patch too small" if patch_radius <= 0.0 or repeats < 2 else super.validate()
