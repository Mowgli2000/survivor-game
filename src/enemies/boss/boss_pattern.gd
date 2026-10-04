class_name BossPattern
extends Resource
## One boss attack (strategy, ADR 0014): telegraphed during `windup` (the boss
## stands still), fired `repeats` times `repeat_interval` apart, then `recovery`
## seconds of normal movement. Shared by every boss of a type: no per-boss
## state here (BossDirector owns it).

@export var windup: float = 0.7
@export var repeats: int = 1
@export var repeat_interval: float = 0.3
@export var recovery: float = 1.2

@export_group("Projectiles")
@export var projectile_speed: float = 320.0
## Multiplied by the boss's wave damage multiplier.
@export var projectile_damage: float = 12.0
@export var projectile_radius: float = 12.0


## Called once when the windup starts. `aim` = player position at that moment.
func telegraph(_ctx: BossContext, _boss: Enemy, _aim: Vector2) -> void:
	pass


## Called `repeats` times after the windup (`repeat` = 0, 1...).
func fire(_ctx: BossContext, _boss: Enemy, _aim: Vector2, _repeat: int) -> void:
	pass


## Data validation (tests): "" when valid.
func validate() -> String:
	if windup < 0.0 or repeats < 1 or repeat_interval < 0.0 or recovery < 0.0:
		return "invalid timing"
	return ""


func _shoot(ctx: BossContext, boss: Enemy, direction: Vector2) -> void:
	ctx.enemy_projectiles.spawn(boss.position, direction * projectile_speed,
		projectile_damage * boss.damage_multiplier, projectile_radius, boss.data.projectile_style)


func _warn_circle(ctx: BossContext, boss: Enemy, radius: float) -> void:
	if ctx.vfx != null and windup > 0.0:
		ctx.vfx.warning_circle(boss.position, radius, boss.data.color, windup)


func _warn_line(ctx: BossContext, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	if ctx.vfx != null and windup > 0.0:
		ctx.vfx.warning_line(from, to, width, color, windup)
