class_name HailPattern
extends BossPattern
## Hail falls around the player: each volley marks `stones` random spots near the player (shown for one
## interval) and the stones land together on the next volley. No fixed spot is safe: keep reading the ground.

@export var stones: int = 4
@export var scatter: float = 330.0
@export var stone_radius: float = 80.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_mark(ctx, boss, aim, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	for k in stones:
		var at := _spot(boss, k)
		_hurt_circle(ctx, boss, at, stone_radius)
		_strike_fx(ctx, boss, at, stone_radius)
	_shake(ctx, 0.15)
	if repeat + 1 < repeats:
		_mark(ctx, boss, ctx.target_position(boss.position), repeat_interval, ctx)


## Chooses and shows this volley's spots. The spots are kept in the boss's `special_dir` seed: the same random
## sequence for the warning and for the landing, without state in this shared resource.
func _mark(ctx: BossContext, boss: Enemy, center: Vector2, life: float, _unused: Variant = null) -> void:
	boss.special_dir = center
	boss.special_timer = ctx.rng.randf() * 1000.0 if ctx.rng != null else 0.0
	if ctx.vfx != null:
		for k in stones:
			ctx.vfx.warning_circle(_spot(boss, k), stone_radius, boss.data.color, life)


## Spot `k` of the marked volley: around `special_dir`, from the seed in `special_timer`.
func _spot(boss: Enemy, k: int) -> Vector2:
	# Stones sit on a ring (turned at random each volley): two stones never overlap, however the seed falls.
	var angle := fmod(boss.special_timer * 2.399963, TAU) + TAU * k / stones
	var distance := scatter * (0.62 + 0.12 * fmod(boss.special_timer * 0.618034 + k * 0.37, 1.0))
	return boss.special_dir + Vector2.from_angle(angle) * distance


func validate() -> String:
	return "hail needs stones" if stones < 1 or stone_radius <= 0.0 else super.validate()
