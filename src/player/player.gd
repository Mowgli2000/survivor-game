class_name Player
extends CharacterBody2D
## The controlled character: movement, health, invulnerability frames.
## Weapons live in the WeaponHolder child; stats in `stats`.

signal health_changed(hp: float, max_hp: float)
signal damaged(amount: float)
signal died
## A hit was avoided (dodge stat).
signal dodged

## Sprite height in px per px of collision radius.
const SPRITE_HEIGHT_PER_RADIUS := 6.4
## Feet sit this fraction of the radius below the player center.
const SPRITE_FOOT := 0.8
## Opacity of a dead player waiting for the next wave (coop).
const GHOST_ALPHA := 0.3

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
## Gameplay rolls (dodge). Run replaces it with the run RNG (replays).
var rng := RandomNumberGenerator.new()
var animator := SpriteAnimator.new()

var _data: CharacterData
var _arena: Rect2
var _invulnerable: float = 0.0
var _last_max_hp: float = 0.0


func setup(data: CharacterData, arena: Rect2) -> void:
	_data = data
	_arena = arena
	radius = data.radius
	var path := "res://assets/sprites/%s.tres" % data.sprite_id
	var has_sprite := data.sprite_id != &"" and ResourceLoader.exists(path)
	animator.reset(load(path) as SpriteSheet if has_sprite else null, 0.0)
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


func _physics_process(delta: float) -> void:
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
	if party != null and party.size() > 1:
		position = party.clamp_spread(self, position)
	var anim := &"walk" if velocity.length_squared() > 4.0 else &"idle"
	if animator.advance(delta, anim, velocity.x):
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
	if is_dead or invincible or _invulnerable > 0.0:
		return
	if rng.randf() < stats.get_value(StatIds.DODGE):
		dodged.emit()
		return
	var damage := CombatMath.apply_armor(amount, stats.get_value(StatIds.ARMOR))
	hp = maxf(hp - damage, 0.0)
	_invulnerable = _data.invulnerability_time
	damaged.emit(damage)
	health_changed.emit(hp, stats.get_value(StatIds.MAX_HP))
	if hp <= 0.0:
		is_dead = true
		# Coop: a dead player stays as a ghost until the next wave (ADR 0017).
		modulate.a = GHOST_ALPHA
		died.emit()


## Back in the fight with full health (coop: next wave after a death).
func revive() -> void:
	if not is_dead:
		return
	is_dead = false
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
	if animator.sheet != null:
		animator.sheet.draw(self, animator.frame, radius * SPRITE_HEIGHT_PER_RADIUS, radius * SPRITE_FOOT,
			animator.facing, Color.WHITE)
		return
	var color := _data.color if _data != null else Color.WHITE
	var neon := Color(0.3, 0.9, 1.0)
	draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 32, Color(neon, 0.3), 6.0, true)
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius - 1.0, 0.0, TAU, 32, neon, 3.0, true)
	draw_circle(Vector2(radius * 0.45, 0.0), radius * 0.25, Color(0.05, 0.05, 0.08))
