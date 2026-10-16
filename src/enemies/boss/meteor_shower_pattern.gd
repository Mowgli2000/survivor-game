class_name MeteorShowerPattern
extends BossPattern
## Three huge meteors are called down in a row across the player's path, with a long warning (the three
## craters are shown at the windup): the gaps between them are narrow, and the player has to pick one and
## reach it in time.

@export var meteors: int = 3
@export var crater_radius: float = 165.0
@export var gap: float = 380.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx == null:
		return
	for k in meteors:
		ctx.vfx.warning_circle(crater(boss, aim, k), crater_radius, boss.data.color, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	for k in meteors:
		var at := crater(boss, aim, k)
		_hurt_circle(ctx, boss, at, crater_radius)
		_strike_fx(ctx, boss, at, crater_radius * 1.5)
	_shake(ctx, 0.5)


## Crater `k`: in a line across the dragon-to-player direction, centered on the player.
func crater(boss: Enemy, aim: Vector2, k: int) -> Vector2:
	var across := _dir_to(boss.position, aim).orthogonal()
	return aim + across * gap * (k - (meteors - 1) * 0.5)


func validate() -> String:
	return "meteors need a count and a radius" if meteors < 1 or crater_radius <= 0.0 else super.validate()
