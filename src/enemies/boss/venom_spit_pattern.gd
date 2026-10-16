class_name VenomSpitPattern
extends BossPattern
## The queen spits slow, fat blobs of venom at the player in quick bursts: each blob flies on its own slightly
## different line, so the burst covers a wide fan (the first line is shown at the windup).

@export var blobs: int = 3
@export var scatter_degrees: float = 30.0
@export var blob_speed: float = 230.0
@export var blob_radius: float = 22.0


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	_warn_line(ctx, boss.position, boss.position + _dir_to(boss.position, aim) * 480.0, blob_radius * 2.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, _aim: Vector2, _repeat: int) -> void:
	var base := (ctx.target_position(boss.position) - boss.position).angle()
	for k in blobs:
		var jitter := (ctx.rng.randf() - 0.5) * deg_to_rad(scatter_degrees) if ctx.rng != null else 0.0
		var direction := Vector2.from_angle(base + jitter)
		ctx.enemy_projectiles.spawn(boss.position, direction * blob_speed * ctx.speed_scale,
			_damage(boss), blob_radius, boss.data.projectile_style)


func validate() -> String:
	return "spit needs blobs" if blobs < 1 or blob_speed <= 0.0 else super.validate()
