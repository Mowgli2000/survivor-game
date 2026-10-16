class_name FrostWallPattern
extends BossPattern
## A wall of ice blocks heaves up across the player's path, with one opening (the wall is shown at the windup,
## the gap left clear). A second, nearer wall rises with its opening on the other side: slide through the first
## gap, then cross to the second.

@export var wall_length: float = 760.0
@export var gap_width: float = 170.0
@export var first_distance: float = 330.0
@export var wall_step: float = 190.0
@export var thickness: float = 60.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	for repeat in repeats:
		for piece in pieces(boss, aim, repeat):
			var life := scaled_windup(ctx) + repeat * repeat_interval
			if ctx.vfx != null:
				ctx.vfx.warning_line(piece[0], piece[1], thickness * 2.0, boss.data.color, life)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	for piece in pieces(boss, aim, repeat):
		_hurt_segment(ctx, boss, piece[0], piece[1], thickness)
		_strike_fx(ctx, boss, (piece[0] + piece[1]) * 0.5, piece[0].distance_to(piece[1]) * 0.5 + thickness, (aim - boss.position).angle() + PI * 0.5)
	_shake(ctx, 0.3)


## The solid parts of wall `repeat` as [from, to] pairs (the wall minus its gap). The gap is left of the
## player's line on even walls and right of it on odd ones.
func pieces(boss: Enemy, aim: Vector2, repeat: int) -> Array:
	var along := _dir_to(boss.position, aim)
	var across := along.orthogonal()
	var center := boss.position + along * (first_distance + wall_step * repeat)
	var half := wall_length * 0.5
	var gap_center := (-1.0 if repeat % 2 == 0 else 1.0) * half * 0.35
	var gap_from := gap_center - gap_width * 0.5
	var gap_to := gap_center + gap_width * 0.5
	return [[center + across * -half, center + across * gap_from], [center + across * gap_to, center + across * half]]


func validate() -> String:
	return "frost wall needs a length and a gap" if wall_length <= gap_width or thickness <= 0.0 else super.validate()
