class_name StormFrontPattern
extends BossPattern
## A storm front rolls across the arena in front of the dragon: bolts of lightning strike one spot after the
## other along a line that advances from the dragon toward the player and beyond. Each spot is shown one
## interval before its bolt, never more: the player must read the ground and keep moving sideways.

@export var bolt_radius: float = 75.0
@export var first_distance: float = 200.0
@export var advance: float = 135.0
@export var wobble: float = 170.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_mark(ctx, boss, aim, 0, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var at := spot(boss, aim, repeat)
	_hurt_circle(ctx, boss, at, bolt_radius)
	_strike_fx(ctx, boss, at, bolt_radius * 1.8)
	_shake(ctx, 0.12)
	if repeat + 1 < repeats:
		_mark(ctx, boss, aim, repeat + 1, repeat_interval)


func _mark(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int, life: float) -> void:
	if ctx.vfx != null:
		ctx.vfx.warning_circle(spot(boss, aim, repeat), bolt_radius, boss.data.color, life)


## Bolt `k`: along the line from the dragon through the player, wavering left and right in turn.
func spot(boss: Enemy, aim: Vector2, k: int) -> Vector2:
	var along := _dir_to(boss.position, aim)
	var side := along.orthogonal() * wobble * sin(k * 2.1)
	return boss.position + along * (first_distance + advance * k) + side


func validate() -> String:
	return "storm needs bolts" if bolt_radius <= 0.0 or repeats < 3 else super.validate()
