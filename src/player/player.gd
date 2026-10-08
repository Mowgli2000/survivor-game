class_name Player
extends CharacterBody2D
## The controlled character: movement, health, invulnerability frames.
## Weapons live in the WeaponHolder child; stats in `stats`.

signal health_changed(hp: float, max_hp: float)
signal damaged(amount: float)
signal died
## A hit was avoided (dodge stat).
signal dodged
## The drop out of the gate at the start of a run ended (enter_from).
signal landed

## Sprite height in px per px of collision radius.
const SPRITE_HEIGHT_PER_RADIUS := 6.4
## The walk cycle plays at its drawn speed at this movement speed (the base speed) and
## faster or slower with the real one, so the feet do not slide as much (playtest: a
## fast hunter seemed to walk backward). Kept within WALK_RATE_MIN..WALK_RATE_MAX.
const WALK_ANIM_SPEED := 300.0
const WALK_RATE_MIN := 0.6
const WALK_RATE_MAX := 1.8
## Feet sit this fraction of the radius below the player center.
const SPRITE_FOOT := 0.8
## Opacity of a dead player waiting for the next wave (coop).
const GHOST_ALPHA := 0.3
## Default seconds of the drop out of the portal (enter_from).
const ARRIVAL_SECONDS := 0.85
const SPRITE_SHADER := preload("res://src/player/player_sprite.gdshader")

var stats: StatBlock
var hp: float = 1.0
var radius: float = 16.0
var is_dead: bool = false
## Debug/tests: ignore all damage.
var invincible: bool = false
## Debug/tests: when valid, replaces the player input. Must return a Vector2.
var bot_input: Callable
## Movement devices (ADR 0017). Null = the plain move_* actions.
var input: PlayerInput
## 0-based player number (coop); also the EnemyManager.damage_source of its weapons.
var index: int = 0
## Set by Run: keeps the players close together (coop).
var party: Party
## Coop: ring of the player's color at its feet (transparent = none).
var tag_color := Color(0, 0, 0, 0)

var weapons: WeaponHolder
## Weapons drawn around the player (set up by Run once the enemies exist).
var weapon_visuals: WeaponVisuals
## HP bar above the head (null in tests that skip setup()).
var health_bar: PlayerHealthBar
## Gameplay rolls (dodge). Run replaces it with the run RNG (replays).
var rng := RandomNumberGenerator.new()
var animator := SpriteAnimator.new()
## Lean, hit squash and dust drawn over the baked frames.
var motion := PlayerMotion.new()
## Articulated puppet (CharacterData.rig), drawn instead of the baked sprite.
var rig: CharacterRig

var _data: CharacterData
## 0 = the character's own look, 1 = its second look (CharacterData.alt_*).
var _variant: int = 0
var _arena: Rect2
var _invulnerable: float = 0.0
var _last_max_hp: float = 0.0
var _arrival_left: float = 0.0
var _arrival_total: float = ARRIVAL_SECONDS
## Where the drop starts, relative to the landing spot.
var _arrival_offset: Vector2 = Vector2.ZERO



## Walk animation speed factor for a movement speed (see WALK_ANIM_SPEED).
static func walk_anim_rate(speed: float) -> float:
	return clampf(speed / WALK_ANIM_SPEED, WALK_RATE_MIN, WALK_RATE_MAX)


func setup(data: CharacterData, arena: Rect2, variant: int = 0) -> void:
	_data = data
	_variant = variant
	_arena = arena
	radius = data.radius
	var sprite_id := data.sprite_id_for(variant)
	var path := "res://assets/sprites/%s.tres" % sprite_id
	var has_sprite := sprite_id != &"" and ResourceLoader.exists(path)
	animator.reset(load(path) as SpriteSheet if has_sprite else null, 0.0)
	if has_sprite:
		_setup_sprite_material(animator.sheet)
	if data.rig != null and variant == 0:
		rig = CharacterRig.new()
		rig.name = "Rig"
		rig.setup(data.rig)
		add_child(rig)
		_place_rig()
	stats = StatBlock.from_defaults(data.stat_overrides)
	hp = stats.get_value(StatIds.MAX_HP)
	_last_max_hp = hp
	stats.changed.connect(_on_stat_changed)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	weapons = WeaponHolder.new()
	weapons.name = "Weapons"
	add_child(weapons)

	weapon_visuals = WeaponVisuals.new()
	weapon_visuals.name = "WeaponVisuals"
	add_child(weapon_visuals)

	if stats != null:
		health_bar = PlayerHealthBar.new()
		health_bar.name = "HealthBar"
		add_child(health_bar)
		health_bar.setup(self, head_height())


## The hero falls from `origin` (global) to where it stands, small and transparent
## at first; controls, weapons and damage wait for the landing.
func enter_from(origin: Vector2, seconds: float = ARRIVAL_SECONDS) -> void:
	_arrival_offset = origin - global_position
	_arrival_total = seconds
	_arrival_left = seconds
	weapon_visuals.visible = false
	if health_bar != null:
		# modulate, not visible: the "HP bar above the hero" setting owns that flag.
		health_bar.modulate.a = 0.0


func _physics_process(delta: float) -> void:
	if rig != null:
		rig.flash = motion.flash
		rig.animate(delta, 0.0 if is_dead else motion.speed_ratio, motion.flash)
		_place_rig()
	if _arrival_left > 0.0:
		_arrival_left -= delta
		animator.advance(delta, &"idle", 1.0)
		if _arrival_left <= 0.0:
			weapon_visuals.visible = true
			if health_bar != null:
				health_bar.modulate.a = 1.0
			landed.emit()
		queue_redraw()
		return
	if is_dead:
		return
	var direction: Vector2
	if bot_input.is_valid():
		direction = bot_input.call()
	elif input != null:
		direction = input.move_vector()
	else:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * stats.get_value(StatIds.MOVE_SPEED)
	move_and_slide()
	position = position.clamp(_arena.position, _arena.end)
	var anim := &"walk" if velocity.length_squared() > 4.0 else &"idle"
	animator.advance(delta * walk_anim_rate(velocity.length()) if anim == &"walk" else delta, anim, velocity.x)
	motion.update(delta, global_position, velocity, stats.get_value(StatIds.MOVE_SPEED))
	_update_sprite_material()
	# Redrawn every frame (lean, dust): one or two players only.
	queue_redraw()

	var regen := stats.get_value(StatIds.HP_REGEN)
	if regen > 0.0:
		heal(regen * delta)

	if _invulnerable > 0.0:
		_invulnerable -= delta
		# Blink while invulnerable.
		modulate.a = 0.4 if fmod(_invulnerable, 0.12) < 0.06 else 1.0
		if _invulnerable <= 0.0:
			modulate.a = 1.0


func take_damage(amount: float) -> void:
	if is_dead or invincible or _invulnerable > 0.0 or _arrival_left > 0.0:
		return
	if rng.randf() < stats.get_value(StatIds.DODGE):
		dodged.emit()
		return
	var damage := CombatMath.apply_armor(amount, stats.get_value(StatIds.ARMOR))
	hp = maxf(hp - damage, 0.0)
	_invulnerable = _data.invulnerability_time
	motion.hurt()
	damaged.emit(damage)
	health_changed.emit(hp, stats.get_value(StatIds.MAX_HP))
	if hp <= 0.0:
		is_dead = true
		# Coop: a dead player stays as a ghost until the next wave (ADR 0017).
		modulate.a = GHOST_ALPHA
		if rig != null:
			rig.die()
		died.emit()


## Back in the fight with full health (coop: next wave after a death).
func revive() -> void:
	if not is_dead:
		return
	is_dead = false
	if rig != null:
		rig.revive()
	_invulnerable = 0.0
	modulate.a = 1.0
	hp = stats.get_value(StatIds.MAX_HP)
	health_changed.emit(hp, hp)


func heal(amount: float) -> void:
	var max_hp := stats.get_value(StatIds.MAX_HP)
	if is_dead or hp >= max_hp:
		return
	hp = minf(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


func is_invulnerable() -> bool:
	return _invulnerable > 0.0


func _on_stat_changed(stat: StringName) -> void:
	if stat != StatIds.MAX_HP:
		return
	# Gaining max HP also heals by the same amount; losing it clamps current HP.
	var max_hp := stats.get_value(StatIds.MAX_HP)
	var gained := max_hp - _last_max_hp
	_last_max_hp = max_hp
	hp = clampf(hp + maxf(gained, 0.0), 0.0, max_hp)
	health_changed.emit(hp, max_hp)


func _draw() -> void:
	if tag_color.a > 0.0:
		var feet := Vector2(0.0, radius * SPRITE_FOOT)
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, radius * 1.5, 0.0, TAU, 32, tag_color, 5.0, true)
		draw_set_transform(Vector2.ZERO)
	if rig != null:
		var feet := Vector2(0.0, radius * SPRITE_FOOT)
		# Ground shadow (the baked sprites have it in their frames).
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, radius * 1.7, Color(0.05, 0.03, 0.12, 0.35 if not is_dead else 0.0))
		draw_set_transform(Vector2.ZERO)
		_draw_dust(feet)
		return
	if animator.sheet != null:
		_draw_sprite()
		return
	var color := _data.color if _data != null else Color.WHITE
	var neon := Color(0.3, 0.9, 1.0)
	draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 32, Color(neon, 0.3), 6.0, true)
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius - 1.0, 0.0, TAU, 32, neon, 3.0, true)
	draw_circle(Vector2(radius * 0.45, 0.0), radius * 0.25, Color(0.05, 0.05, 0.08))


func _draw_dust(feet: Vector2) -> void:
	for i in motion.dust_positions.size():
		var r := motion.dust_ages[i] / PlayerMotion.DUST_LIFE
		var at := motion.dust_positions[i] - global_position + feet + Vector2(0.0, -r * radius * 0.3)
		draw_circle(at, radius * (0.2 + r * 0.45), Color(0.9, 0.88, 0.95, 0.4 * (1.0 - r)))


## Distance from the center to the top of the sprite (where the HP bar sits).
func head_height() -> float:
	var height := radius * SPRITE_HEIGHT_PER_RADIUS * (_data.sprite_scale_for(_variant) if _data != null else 1.0)
	return height - radius * SPRITE_FOOT


## The puppet stands on the feet, as tall as the sprite would be, leaning and
## squashed like it (PlayerMotion). body_scale().x already holds the facing
## (mirrored when moving left): it must not be applied twice.
func _place_rig() -> void:
	var height := radius * SPRITE_HEIGHT_PER_RADIUS * (_data.sprite_scale_for(_variant) if _data != null else 1.0)
	var s := height / rig.rig.height
	var squash := motion.body_scale()
	rig.transform = Transform2D(motion.lean, Vector2(s * squash.x, s * squash.y), 0.0,
		Vector2(0.0, radius * SPRITE_FOOT))


func _setup_sprite_material(sheet: SpriteSheet) -> void:
	var atlas := Vector2(sheet.texture.get_size())
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SPRITE_SHADER
	shader_material.set_shader_parameter(&"cell_v_top", sheet.origin.y / atlas.y)
	shader_material.set_shader_parameter(&"cell_v_height", sheet.cell_size.y / atlas.y)
	shader_material.set_shader_parameter(&"cell_u_width", sheet.cell_size.x / atlas.x)
	material = shader_material


func _update_sprite_material() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter(&"sway", motion.speed_ratio)
	shader_material.set_shader_parameter(&"flash", motion.flash)


## Dust, then the body leaning around its feet.
func _draw_sprite() -> void:
	var sheet := animator.sheet
	var height := radius * SPRITE_HEIGHT_PER_RADIUS * (_data.sprite_scale_for(_variant) if _data != null else 1.0)
	var foot := radius * SPRITE_FOOT
	var feet := Vector2(0.0, foot)
	_draw_dust(feet)

	var body := Transform2D(motion.lean, motion.body_scale(), 0.0, feet) * Transform2D(0.0, -feet)
	var tint := Color.WHITE
	if _arrival_left > 0.0:
		# Gravity: slow at the gate, fast at the ground.
		var t := 1.0 - _arrival_left / _arrival_total
		var shadow := Transform2D(0.0, Vector2(1.0, 0.35), 0.0, feet)
		draw_set_transform_matrix(shadow)
		draw_circle(Vector2.ZERO, radius * 1.7 * t, Color(0.05, 0.03, 0.12, 0.35 * t))
		body = Transform2D(0.0, Vector2.ONE * lerpf(0.3, 1.0, t), 0.0, _arrival_offset * (1.0 - t * t)) * body
		tint.a = clampf(t * 4.0, 0.0, 1.0)
	draw_set_transform_matrix(body)
	sheet.draw(self, animator.frame, height, foot, 1.0, tint)
	draw_set_transform_matrix(Transform2D.IDENTITY)
