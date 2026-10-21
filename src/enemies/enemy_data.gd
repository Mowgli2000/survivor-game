class_name EnemyData
extends Resource
## Definition of an enemy type. Instances live in data/enemies/.

enum Movement {
	CHASE,   ## Runs straight at the player.
	RANGED,  ## Keeps its distance, strafes and shoots.
	CHARGER,  ## Chases; in range, stops to telegraph, then rushes in a straight line.
	KAMIKAZE,  ## Chases; close to the player, burns a fuse then explodes (no XP).
	SPAWNER,  ## Chases slowly and calls minions every few seconds.
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
## Look of this enemy's shots, boss patterns included (an ENEMY_* style).
@export var projectile_style: WeaponData.ProjectileStyle = WeaponData.ProjectileStyle.ENEMY_ORB

@export_group("Special (charger / kamikaze / spawner)")
@export var charge_range: float = 380.0
@export var charge_windup: float = 0.6
@export var charge_speed: float = 700.0
@export var charge_duration: float = 0.45
@export var charge_cooldown: float = 2.5
@export var fuse_range: float = 70.0
@export var fuse_time: float = 0.55
@export var blast_radius: float = 110.0
## Multiplied by the wave damage multiplier.
@export var blast_damage: float = 18.0
@export var spawn_enemy: EnemyData
@export var spawn_count: int = 3
@export var spawn_cooldown: float = 4.0

@export_group("Rewards")
@export var xp_value: int = 1
## > 0: killing it grants a random item of this tier or higher (bosses).
@export var reward_item_tier: int = 0
## A boss that drops a treasure chest when it dies (its reward comes out of the chest instead of at once).
@export var chest: ChestData

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
## Boss attack animation (strip of frames, own texture): played by BossDirector over each
## attack. Empty: the boss keeps its walk / idle sprite.
@export var attack_sheet: SpriteSheet
## Size of the attack frames relative to the walk ones (the knight's share of the cell).
@export var attack_scale: float = 1.0
## How long each attack frame lasts, relative to the others (empty: all equal). Slow windup, fast strike.
@export var attack_frame_weights: PackedFloat32Array = PackedFloat32Array()
## The frame where the blow lands: it starts as the pattern's windup ends (-1: half way through).
@export var attack_strike_frame: int = -1
## Where the mouth is on an attack frame (px of the frame, facing right), for breath attacks that must start there.
## Zero: the attacks start at the body center.
@export var mouth_cell: Vector2 = Vector2.ZERO


## Share (0..1) of the attack animation that comes before the strike frame.
func attack_strike_share() -> float:
	if attack_sheet == null or attack_strike_frame < 0:
		return 0.5
	var total := 0.0
	var before := 0.0
	var frames := maxi(attack_sheet.animations.get(&"attack", Vector3i(0, 1, 1)).y, 1)
	for i in frames:
		var weight := attack_frame_weight(i)
		total += weight
		if i < attack_strike_frame:
			before += weight
	return clampf(before / maxf(total, 0.001), 0.05, 0.95)


func attack_frame_weight(index: int) -> float:
	return attack_frame_weights[index] if index < attack_frame_weights.size() else 1.0

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
	if attack_sheet != null and attack_sheet.has_animation(&"walk"):
		return attack_sheet  # a boss painted entirely in its own sheet (walk, idle, attack, entrance...)
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
