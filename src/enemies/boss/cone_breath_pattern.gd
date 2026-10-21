class_name ConeBreathPattern
extends BossPattern
## Breath (frost, fire): volleys of `count` projectiles in a `spread_degrees`
## cone that sweeps across `sweep_degrees` over the repeats, around the
## direction of the player at the windup (each volley's cone is announced just before it fires).
## Side-stepping out of the sweep is the counter.

@export var count: int = 4
@export var spread_degrees: float = 18.0
@export var sweep_degrees: float = 70.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_volley(ctx, boss, aim, 0, -1.0)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var center := volley_angle(boss.position, aim, repeat)
	var spread := deg_to_rad(spread_degrees)
	for k in count:
		var t := 0.5 if count == 1 else float(k) / (count - 1)
		_shoot(ctx, boss, Vector2.from_angle(center - spread * 0.5 + spread * t))
	if repeat + 1 < repeats:
		_warn_volley(ctx, boss, aim, repeat + 1, repeat_interval)


## Announces the cone of volley `repeat` for `seconds` (default: the windup).
func _warn_volley(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int, seconds: float) -> void:
	var length := projectile_speed * ctx.speed_scale * 0.8
	_warn_sector(ctx, boss, boss.position, volley_angle(boss.position, aim, repeat), length,
			deg_to_rad(spread_degrees) * 0.5, seconds)


## Center of volley `repeat`: from one edge of the sweep to the other.
func volley_angle(from: Vector2, aim: Vector2, repeat: int) -> float:
	var base := (aim - from).angle()
	var sweep := deg_to_rad(sweep_degrees)
	var t := 0.5 if repeats <= 1 else float(repeat) / (repeats - 1)
	return base - sweep * 0.5 + sweep * t


func validate() -> String:
	return "count < 1" if count < 1 else super.validate()
