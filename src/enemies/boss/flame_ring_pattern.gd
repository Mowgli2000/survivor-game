class_name FlameRingPattern
extends BossPattern
## Rings of fire close in on the spot where the player stood at the windup: each volley is a
## band of flame at a smaller radius, with an opening that turns a little every time. Cross a
## band through its opening, or be burnt.

const CHORDS := 20

@export var start_radius: float = 330.0
@export var radius_step: float = 100.0
@export var band: float = 45.0
@export var gap_degrees: float = 100.0
@export var gap_turn_degrees: float = 50.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_ring(ctx, boss, aim, 0, scaled_windup(ctx))


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var radius := ring_radius(repeat)
	var gap := gap_angle(boss, aim, repeat)
	for player in ctx.party.members:
		if player.is_dead:
			continue
		var offset := player.global_position - aim
		var inside_band := absf(offset.length() - radius) <= band + player.radius
		if inside_band and not _in_gap(gap, offset.angle()):
			player.take_damage(_damage(boss))
	for k in CHORDS:
		var angle := TAU * (k + 0.5) / CHORDS
		if not _in_gap(gap, angle):
			_strike_fx(ctx, boss, aim + Vector2.from_angle(angle) * radius, band * 2.0)
	_shake(ctx, 0.2)
	if repeat + 1 < repeats:
		_warn_ring(ctx, boss, aim, repeat + 1, repeat_interval)  # each ring is announced just before it burns


## Announces ring `repeat` with its opening (an arc of the ring band).
func _warn_ring(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int, seconds: float) -> void:
	if ctx.vfx == null:
		return
	var radius := ring_radius(repeat)
	var gap := gap_angle(boss, aim, repeat)
	var half_gap := deg_to_rad(gap_degrees) * 0.5
	ctx.vfx.warning_ring(aim, maxf(radius - band, 0.0), radius + band, boss.data.color, seconds, gap + half_gap, gap - half_gap + TAU)


func ring_radius(repeat: int) -> float:
	return maxf(start_radius - radius_step * repeat, 0.0)


## Direction of the opening of ring `repeat`: first facing the boss, turning each volley.
func gap_angle(boss: Enemy, aim: Vector2, repeat: int) -> float:
	return (boss.position - aim).angle() + deg_to_rad(gap_turn_degrees) * repeat


func validate() -> String:
	if band <= 0.0 or radius_step <= 0.0 or gap_degrees <= 0.0 or gap_degrees >= 360.0:
		return "flame ring needs a band, a step and an opening"
	return super.validate()


func _in_gap(gap: float, angle: float) -> bool:
	return absf(angle_difference(gap, angle)) <= deg_to_rad(gap_degrees) * 0.5
