class_name RadialBurstPattern
extends BossPattern
## Ring of `count` projectiles around the boss, turned by `rotation_step`
## degrees on each repeat (spirals).

@export var count: int = 12
@export var rotation_step: float = 0.0


func telegraph(ctx: BossContext, boss: Enemy, _aim: Vector2) -> void:
	_warn_circle(ctx, boss, boss.radius * 3.0)


func fire(ctx: BossContext, boss: Enemy, _aim: Vector2, repeat: int) -> void:
	var offset := deg_to_rad(rotation_step) * repeat
	for k in count:
		_shoot(ctx, boss, Vector2.from_angle(offset + TAU * k / count))


func validate() -> String:
	return "count < 1" if count < 1 else super.validate()
