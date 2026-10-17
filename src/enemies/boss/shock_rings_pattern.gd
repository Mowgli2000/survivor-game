class_name ShockRingsPattern
extends BossPattern
## Rings of shattered stone spread from the boss one after the other (all of them shown at the windup). Each ring
## hurts only while it passes: stand in the free ground between two rings, then step across a ring once it is gone.

@export var first_radius: float = 170.0
@export var step: float = 160.0
## Half thickness of a ring as a share of its radius (the painted ring is 0.73 inner / outer), at least `min_band`.
@export var band_share: float = 0.15
@export var min_band: float = 28.0


func telegraph(ctx: BossContext, boss: Enemy, _aim: Vector2) -> void:
	_warn_ring(ctx, boss, 0, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, _aim: Vector2, repeat: int) -> void:
	var radius := ring_radius(repeat)
	var half := band(radius)
	_hurt_ring(ctx, boss, boss.position, radius - half, radius + half)
	_strike_fx(ctx, boss, boss.position, radius + half)
	_shake(ctx, 0.2)
	if repeat + 1 < repeats:
		_warn_ring(ctx, boss, repeat + 1, repeat_interval)  # each ring is announced just before it spreads


func _warn_ring(ctx: BossContext, boss: Enemy, repeat: int, seconds: float) -> void:
	if ctx.vfx != null:
		var radius := ring_radius(repeat)
		var half := band(radius)
		ctx.vfx.warning_ring(boss.position, radius - half, radius + half, boss.data.color, seconds)


func ring_radius(repeat: int) -> float:
	return first_radius + step * repeat


## Half thickness of the ring of radius `radius`.
func band(radius: float) -> float:
	return maxf(radius * band_share, min_band)


func validate() -> String:
	return "rings need a band and a step" if band_share <= 0.0 or step <= 0.0 or first_radius <= 0.0 else super.validate()
