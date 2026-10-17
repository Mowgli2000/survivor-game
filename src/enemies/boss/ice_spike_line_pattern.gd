class_name IceSpikeLinePattern
extends BossPattern
## A line of ice spikes erupts from the giant toward where the player stood at the windup, one spike after the
## other (each spot shown at the windup, with its own delay): sidestep the line, or time the run through it.

@export var spikes: int = 5
@export var first_distance: float = 140.0
@export var spacing: float = 130.0
@export var spike_radius: float = 60.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	if ctx.vfx == null:
		return
	for k in spikes:
		ctx.vfx.warning_circle(spot(boss, aim, k), spike_radius, boss.data.color, scaled_windup(ctx) + k * repeat_interval)


## One spike per volley: `repeats` must equal `spikes`.
func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	var at := spot(boss, aim, repeat)
	_hurt_circle(ctx, boss, at, spike_radius)
	_strike_fx(ctx, boss, at, spike_radius, (aim - boss.position).angle())
	if repeat % 3 == 0:
		_shake(ctx, 0.12)


func spot(boss: Enemy, aim: Vector2, k: int) -> Vector2:
	return boss.position + _dir_to(boss.position, aim) * (first_distance + spacing * k)


func validate() -> String:
	if spikes < 1 or repeats != spikes:
		return "an ice spike line has one volley per spike"
	return super.validate()
