class_name ShockRingsPattern
extends BossPattern
## Rings of broken ground spread outward from the idol one after the other (all shown at the windup, as
## dotted bands); each ring has an opening: step through it, or jump from the gap of one ring to the next.

const CHORDS := 24

@export var first_radius: float = 170.0
@export var step: float = 120.0
@export var band: float = 38.0
@export var gap_degrees: float = 90.0
@export var gap_turn_degrees: float = 70.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx == null:
		return
	for repeat in repeats:
		var radius := first_radius + step * repeat
		var gap := gap_angle(boss, aim, repeat)
		for k in CHORDS:
			var a0 := TAU * k / CHORDS
			var a1 := TAU * (k + 1) / CHORDS
			if not _in_gap(gap, (a0 + a1) * 0.5):
				ctx.vfx.warning_line(boss.position + Vector2.from_angle(a0) * radius, boss.position + Vector2.from_angle(a1) * radius,
					band * 2.0, boss.data.color, scaled_windup(ctx) + repeat * repeat_interval)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var radius := first_radius + step * repeat
	var gap := gap_angle(boss, aim, repeat)
	for player in ctx.party.members:
		if player.is_dead:
			continue
		var offset := player.global_position - boss.position
		if absf(offset.length() - radius) <= band + player.radius and not _in_gap(gap, offset.angle()):
			player.take_damage(_damage(boss))
	_strike_fx(ctx, boss, boss.position, radius + band)
	_shake(ctx, 0.2)


## Opening of ring `repeat`: first facing the player, then turning every ring.
func gap_angle(boss: Enemy, aim: Vector2, repeat: int) -> float:
	return (aim - boss.position).angle() + deg_to_rad(gap_turn_degrees) * repeat


func validate() -> String:
	return "rings need a band and a step" if band <= 0.0 or step <= 0.0 or gap_degrees <= 0.0 or gap_degrees >= 360.0 else super.validate()


func _in_gap(gap: float, angle: float) -> bool:
	return absf(angle_difference(gap, angle)) <= deg_to_rad(gap_degrees) * 0.5
