class_name ImpactZonesPattern
extends BossPattern
## Strikes from above (icicles, meteors): circles shown on the ground at the
## windup, then each one hits every player inside it. Volley 0 lands on the
## player's position and a ring around it; each repeat lands on a wider ring.
## Uses `projectile_damage` (scaled by the boss's damage multiplier).

@export var count: int = 5
@export var zone_radius: float = 70.0
## Distance between the ring of volley 0 and the player's position.
@export var scatter: float = 170.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx == null:
		return
	for repeat in repeats:
		for pos in zones(boss.position, aim, repeat):
			ctx.vfx.warning_circle(pos, zone_radius, boss.data.color, windup + repeat * repeat_interval)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var damage := projectile_damage * boss.damage_multiplier
	for pos in zones(boss.position, aim, repeat):
		if ctx.vfx != null:
			ctx.vfx.explosion(pos, zone_radius, boss.data.color, false)
		for player in ctx.party.members:
			var reach := zone_radius + player.radius
			if not player.is_dead and pos.distance_squared_to(player.global_position) <= reach * reach:
				player.take_damage(damage)


## Centers of volley `repeat`: the aim plus a ring (volley 0), then wider rings
## turned by half a step so they cover the gaps of the previous one.
func zones(from: Vector2, aim: Vector2, repeat: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	var ring := count
	if repeat == 0:
		result.append(aim)
		ring = count - 1
	var start := (aim - from).angle() + (PI / maxi(ring, 1)) * repeat
	for k in ring:
		result.append(aim + Vector2.from_angle(start + TAU * k / ring) * scatter * (repeat + 1))
	return result


func validate() -> String:
	if count < 1 or zone_radius <= 0.0:
		return "impact zones need a count and a radius"
	return super.validate()
