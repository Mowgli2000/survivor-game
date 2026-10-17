class_name BladeRainPattern
extends BossPattern
## Blades fall in vertical strips across the arena around the player; one strip per volley is
## left free and that lane moves by one strip each volley, so the player has to keep sliding
## sideways to stay in it.

@export var strips: int = 9
@export var strip_width: float = 90.0
@export var half_height: float = 520.0

## Painted blade bar thickness is about a quarter of its frame: the frame is this many strip widths tall.
const STRIP_ART_HEIGHT := 3.4
const WARNING_SHARE := 0.82
const LANE_OFFSET := 2


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_volley(ctx, boss, aim, 0, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var free := lane(aim, repeat)
	for i in strips:
		if i == free:
			continue
		var x := strip_x(aim, i)
		_hurt_segment(ctx, boss, Vector2(x, aim.y - half_height), Vector2(x, aim.y + half_height), strip_width * 0.5)
		if effect != null and ctx.vfx != null:
			ctx.vfx.sheet_stretch(effect, Vector2(x, aim.y - half_height), Vector2(x, aim.y + half_height), strip_width * STRIP_ART_HEIGHT)
		else:
			for k in 5:
				_strike_fx(ctx, boss, Vector2(x, aim.y + (k - 2) * half_height * 0.45), strip_width * 0.9)
	_shake(ctx, 0.25)
	if repeat + 1 < repeats:
		_warn_volley(ctx, boss, aim, repeat + 1, repeat_interval)  # only the next volley is announced: no overlapping bands


## Announces the strips of volley `repeat` (thinner than the strips so neighbours stay apart; the free lane is the gap).
func _warn_volley(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int, seconds: float) -> void:
	if ctx.vfx == null:
		return
	for i in strips:
		if i != lane(aim, repeat):
			var x := strip_x(aim, i)
			ctx.vfx.warning_line(Vector2(x, aim.y - half_height), Vector2(x, aim.y + half_height),
				strip_width * WARNING_SHARE, boss.data.color, seconds)


## Center of strip `i`: strip `strips / 2` is the one under the aim.
func strip_x(aim: Vector2, i: int) -> float:
	return aim.x + (i - strips / 2) * strip_width


## Free strip of volley `repeat`: LANE_OFFSET strips away from the one under the aim (the hero must move to reach it),
## then one more to the side each volley.
func lane(aim: Vector2, repeat: int) -> int:
	var direction := 1 if int(absf(aim.x)) % 2 == 0 else -1
	return clampi(strips / 2 + direction * (LANE_OFFSET + repeat), 0, strips - 1)


func validate() -> String:
	if strips < 3 or strip_width <= 0.0:
		return "blade rain needs strips"
	return super.validate()
