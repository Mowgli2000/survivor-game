class_name EnemyData
extends Resource
## Definition of an enemy type. Instances live in data/enemies/.

enum Movement {
	CHASE,   ## Runs straight at the player.
	RANGED,  ## Keeps its distance, strafes and shoots.
}

@export var id: StringName
@export var name_key: String
@export var movement: Movement = Movement.CHASE
## Killing every living boss ends the current wave at once (Brotato rule:
## on the last wave, it wins the run before the timer).
@export var boss: bool = false

@export_group("Stats")
@export var max_hp: float = 10.0
@export var speed: float = 100.0
@export var contact_damage: float = 5.0
@export var armor: float = 0.0
@export var radius: float = 16.0
## 1.0 = normal knockback, 0.0 = immune.
@export var knockback_taken: float = 1.0

@export_group("Ranged attack")
@export var preferred_distance: float = 380.0
@export var fire_cooldown: float = 2.5
@export var projectile_damage: float = 8.0
@export var projectile_speed: float = 300.0
@export var projectile_radius: float = 9.0

@export_group("Rewards")
@export var xp_value: int = 1
## > 0: killing it grants a random item of this tier or higher (bosses).
@export var reward_item_tier: int = 0

@export_group("Boss")
## Non-empty: boss bar and telegraphed patterns (ADR 0014). Sorted by
## decreasing hp_ratio, the first one at 1.0. `boss` still decides whether
## killing it ends the wave (a mini-boss has phases but boss = false).
@export var phases: Array[BossPhase] = []

@export_group("Visual (placeholder)")
## Neon outline color; the body is a dark version of it.
@export var color: Color = Color(0.9, 0.3, 0.3)
## 0 = circle, otherwise number of polygon sides (3 = triangle...).
@export var shape_sides: int = 0
## Sprite sheet id in assets/sprites/ (empty: neon placeholder shape).
@export var sprite_id: StringName
## Multiplies the sprite colors (e.g. magenta boss reusing another sheet).
@export var sprite_tint: Color = Color.WHITE
## Extra size factor on top of the radius-based sprite size.
@export var sprite_scale: float = 1.0

var _texture: Texture2D
var _elite_texture: Texture2D
var _sheet: SpriteSheet
var _elite_sheet: SpriteSheet


## Placeholder neon sprite of this enemy type, baked on first use (see EnemyArt).
func get_texture() -> Texture2D:
	if _texture == null:
		_texture = EnemyArt.bake(self, color)
	return _texture


## Elite variant: bigger, gold outline. Baked once (the scale is fixed per run).
func get_elite_texture(scale: float) -> Texture2D:
	if _elite_texture == null:
		_elite_texture = EnemyArt.bake(self, EnemyArt.ELITE_OUTLINE, scale)
	return _elite_texture


## Index of the phase active at `hp_ratio` (HP / max HP): the last phase whose
## threshold is reached.
func phase_index_for(hp_ratio: float) -> int:
	var index := 0
	for i in phases.size():
		if hp_ratio <= phases[i].hp_ratio:
			index = i
	return index


## Animated sprite of this type (null: placeholder). Elites use "<id>_elite" when it exists.
func get_sheet(elite: bool) -> SpriteSheet:
	if sprite_id == &"":
		return null
	if _sheet == null:
		_sheet = _load_sheet(String(sprite_id))
	if not elite:
		return _sheet
	if _elite_sheet == null:
		_elite_sheet = _load_sheet(String(sprite_id) + "_elite")
		if _elite_sheet == null:
			_elite_sheet = _sheet
	return _elite_sheet


static func _load_sheet(id: String) -> SpriteSheet:
	var path := "res://assets/sprites/%s.tres" % id
	return load(path) as SpriteSheet if ResourceLoader.exists(path) else null
