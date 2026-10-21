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
## Every volley makes the attack sound, however close they are (a line of spikes rising one after the other).
## Off: volleys closer than BossDirector.SEPARATE_STRIKE_INTERVAL make it once.
@export var sound_per_strike: bool = false

## Outline of this attack's warnings (Vfx.WarnShape): JAGGED cracks, STAR, BLOB. Plain: the disc or band of the damage.
@export_enum("Plain", "Jagged", "Star", "Blob") var warn_shape: int = 0

## Painted effect of this attack (EffectSheet), played where it hits; empty: the plain blast.
@export var effect: EffectSheet

@export_group("Projectiles")
@export var projectile_speed: float = 320.0
## Multiplied by the boss's wave damage multiplier.
@export var projectile_damage: float = 12.0
@export var projectile_radius: float = 12.0


## A windup never gets shorter than this (readable telegraph), unless it is already shorter.
const MIN_WINDUP := 0.5


## `windup` with the fight's pace applied.
func scaled_windup(ctx: BossContext) -> float:
	return maxf(windup * ctx.windup_scale, minf(windup, MIN_WINDUP))


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
	ctx.enemy_projectiles.spawn(boss.position, direction * projectile_speed * ctx.speed_scale,
		projectile_damage * boss.damage_multiplier, projectile_radius, boss.data.projectile_style)


## Damage of one hit of this pattern.
func _damage(boss: Enemy) -> float:
	return projectile_damage * boss.damage_multiplier


## Hurts every living player within `half_width` of the segment (a slash, a falling blade).
func _hurt_segment(ctx: BossContext, boss: Enemy, from: Vector2, to: Vector2, half_width: float) -> void:
	_debug_segment(ctx, from, to, half_width)
	for player in ctx.party.members:
		if player.is_dead:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(player.global_position, from, to)
		if closest.distance_to(player.global_position) <= half_width + player.radius:
			player.take_damage(_damage(boss))


## Hurts every living player in the sector of `radius` around `center`, `half_angle` (rad) each
## side of `facing` (rad).
func _hurt_sector(ctx: BossContext, boss: Enemy, center: Vector2, facing: float, radius: float, half_angle: float,
		inner: float = 0.0) -> void:
	if _shapes_shown(ctx):
		ctx.vfx.debug_circle(center, radius, Vector2.from_angle(facing), cos(half_angle))
		if inner > 0.0:
			ctx.vfx.debug_circle(center, inner, Vector2.from_angle(facing), cos(half_angle))
	for player in ctx.party.members:
		if player.is_dead:
			continue
		var offset := player.global_position - center
		var inside_radius := offset.length() <= radius + player.radius and offset.length() + player.radius >= inner
		if inside_radius and absf(angle_difference(facing, offset.angle())) <= half_angle:
			player.take_damage(_damage(boss))


## The hit of this attack at `at`: the painted `sheet` (default `effect`) fitted to `size` px from its
## center and turned by `angle`, else a plain blast.
## Hurts every living player within `radius` of `center`.
func _hurt_circle(ctx: BossContext, boss: Enemy, center: Vector2, radius: float) -> void:
	if _shapes_shown(ctx):
		ctx.vfx.debug_circle(center, radius, Vector2.RIGHT, -1.0)
	for player in ctx.party.members:
		if not player.is_dead and player.global_position.distance_to(center) <= radius + player.radius:
			player.take_damage(_damage(boss))


## Hurts every living player whose distance to `center` is between `inner` and `outer`.
func _hurt_ring(ctx: BossContext, boss: Enemy, center: Vector2, inner: float, outer: float) -> void:
	if _shapes_shown(ctx):
		ctx.vfx.debug_circle(center, inner, Vector2.RIGHT, -1.0)
		ctx.vfx.debug_circle(center, outer, Vector2.RIGHT, -1.0)
	for player in ctx.party.members:
		if player.is_dead:
			continue
		var distance := player.global_position.distance_to(center)
		if distance + player.radius >= inner and distance - player.radius <= outer:
			player.take_damage(_damage(boss))


## Debug overlay (F4 in game, --shapes in captures): the real damage shapes of the boss attacks.
func _shapes_shown(ctx: BossContext) -> bool:
	return ctx.vfx != null and ctx.vfx.show_shapes


func _debug_segment(ctx: BossContext, from: Vector2, to: Vector2, half_width: float) -> void:
	if _shapes_shown(ctx):
		ctx.vfx.debug_segment(from, to, half_width)


## Unit vector from `from` to `to` (right when they coincide).
func _dir_to(from: Vector2, to: Vector2) -> Vector2:
	var offset := to - from
	return offset.normalized() if offset.length_squared() > 1.0 else Vector2.RIGHT


func _strike_fx(ctx: BossContext, boss: Enemy, at: Vector2, size: float, angle: float = 0.0, sheet: EffectSheet = null) -> void:
	if ctx.vfx == null:
		return
	var painted := sheet if sheet != null else effect
	if painted != null:
		ctx.vfx.sheet_at(painted, at, angle, size)
	else:
		ctx.vfx.explosion(at, size, boss.data.color, false)


## The painted `effect` stretched along a line (a lash, a wave, a thread): `width` is the damage width and `thickness`
## the share of the art's frame its drawing fills, so the painting is as wide as the damage band.
func _strike_line(ctx: BossContext, from: Vector2, to: Vector2, width: float, thickness: float) -> void:
	if ctx.vfx != null and effect != null:
		ctx.vfx.sheet_stretch(effect, from, to, width / thickness)


func _shake(ctx: BossContext, amount: float) -> void:
	if ctx.vfx != null:
		ctx.vfx.shake_requested.emit(amount)


func _warn_circle(ctx: BossContext, boss: Enemy, radius: float) -> void:
	if ctx.vfx != null and windup > 0.0:
		ctx.vfx.warning_circle(boss.position, radius, boss.data.color, scaled_windup(ctx))


## Announces a pie slice (or an annular one) for `seconds` (default: the windup).
func _warn_sector(ctx: BossContext, boss: Enemy, origin: Vector2, facing: float, radius: float, half_angle: float,
		seconds: float = -1.0, inner: float = 0.0) -> void:
	if ctx.vfx != null and (windup > 0.0 or seconds > 0.0):
		ctx.vfx.warning_sector(origin, facing, radius, half_angle, boss.data.color, seconds if seconds > 0.0 else scaled_windup(ctx), inner)


func _warn_line(ctx: BossContext, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	if ctx.vfx != null and windup > 0.0:
		ctx.vfx.warning_line(from, to, width, color, scaled_windup(ctx))
