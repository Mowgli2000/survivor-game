class_name WebNetPattern
extends BossPattern
## Sticky threads shoot across the ground around the player in a net: vertical and horizontal bands (shown at
## the windup) leave square gaps between them. The squares are the only places that are not on a thread.

@export var lines: int = 3
@export var spacing: float = 250.0
@export var half_width: float = 42.0
@export var reach: float = 560.0

## Share of its frame the painted web band fills (measured on the baked sheet).
const ART_THICKNESS := 0.225


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	for band in bands(aim):
		_warn_line(ctx, band[0], band[1], half_width * 2.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	for band in bands(aim):
		_hurt_segment(ctx, boss, band[0], band[1], half_width)
		_strike_line(ctx, band[0], band[1], half_width * 2.0, ART_THICKNESS)
	_shake(ctx, 0.2)


## The threads as [from, to] pairs: `lines` vertical and `lines` horizontal, centered on `aim`.
func bands(aim: Vector2) -> Array:
	var result: Array = []
	for i in lines:
		var offset := (i - (lines - 1) * 0.5) * spacing
		result.append([aim + Vector2(offset, -reach), aim + Vector2(offset, reach)])
		result.append([aim + Vector2(-reach, offset), aim + Vector2(reach, offset)])
	return result


func validate() -> String:
	return "net needs threads" if lines < 1 or spacing <= 0.0 or half_width <= 0.0 else super.validate()
