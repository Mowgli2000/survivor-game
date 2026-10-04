class_name WallPattern
extends BossPattern
## Wave of fire / shockwave: a row of `count` projectiles across the direction
## of the player, all moving towards them, with a `gap` of missing projectiles
## (placed at random) to slip through.

@export var count: int = 14
@export var spacing: float = 46.0
@export var gap: int = 2


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	var direction := _direction(boss.position, aim)
	var half := direction.orthogonal() * spacing * (count - 1) * 0.5
	_warn_line(ctx, boss.position - half, boss.position + half, 10.0, boss.data.color)
	_warn_line(ctx, boss.position, boss.position + direction * projectile_speed * 0.6, 6.0, boss.data.color)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, _repeat: int) -> void:
	var direction := _direction(boss.position, aim)
	var side := direction.orthogonal()
	var hole := ctx.rng.randi_range(0, maxi(count - gap, 0)) if ctx.rng != null else (count - gap) / 2
	for k in count:
		if k >= hole and k < hole + gap:
			continue
		var pos := boss.position + side * spacing * (k - (count - 1) * 0.5)
		ctx.enemy_projectiles.spawn(pos, direction * projectile_speed,
			projectile_damage * boss.damage_multiplier, projectile_radius, boss.data.projectile_style)


func validate() -> String:
	if count < 2 or gap < 1 or gap >= count:
		return "a wall needs at least 2 projectiles and a smaller gap"
	return super.validate()


func _direction(from: Vector2, aim: Vector2) -> Vector2:
	var offset := aim - from
	return offset.normalized() if offset.length_squared() > 1.0 else Vector2.RIGHT
