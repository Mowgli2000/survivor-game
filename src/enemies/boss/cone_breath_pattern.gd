class_name ConeBreathPattern
extends BossPattern
## Breath (frost, fire): volleys of `count` projectiles in a `spread_degrees`
## cone that sweeps across `sweep_degrees` over the repeats, around the
## direction of the player at the windup (shown by the two edge lines).
## Side-stepping out of the sweep is the counter.

@export var count: int = 4
@export var spread_degrees: float = 18.0
@export var sweep_degrees: float = 70.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	var length := projectile_speed * 0.8
	for k in 2:
		var angle := volley_angle(boss.position, aim, k * maxi(repeats - 1, 0))
		_warn_line(ctx, boss.position, boss.position + Vector2.from_angle(angle) * length, 6.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var center := volley_angle(boss.position, aim, repeat)
	var spread := deg_to_rad(spread_degrees)
	for k in count:
		var t := 0.5 if count == 1 else float(k) / (count - 1)
		_shoot(ctx, boss, Vector2.from_angle(center - spread * 0.5 + spread * t))


## Center of volley `repeat`: from one edge of the sweep to the other.
func volley_angle(from: Vector2, aim: Vector2, repeat: int) -> float:
	var base := (aim - from).angle()
	var sweep := deg_to_rad(sweep_degrees)
	var t := 0.5 if repeats <= 1 else float(repeat) / (repeats - 1)
	return base - sweep * 0.5 + sweep * t


func validate() -> String:
	return "count < 1" if count < 1 else super.validate()
