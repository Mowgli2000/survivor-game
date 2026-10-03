class_name CharacterData
extends Resource
## Definition of a playable character. Instances live in data/characters/.

@export var id: StringName
@export var name_key: String
## Hidden from the shop, rewards and selection until a challenge unlocks it (ADR 0015).
@export var locked: bool = false
## Text of the character's rule shown on the selection screen.
@export var description_key: String
## Default starting weapon (when `starting_weapons` is empty or nothing was chosen).
@export var starting_weapon: WeaponData
## Weapons offered on the selection screen (Brotato-style choice).
@export var starting_weapons: Array[WeaponData] = []
## Character bonuses and penalties, applied for the whole run.
@export var modifiers: Array[StatModifier] = []
## Character rule: same effects as items (ADR 0012).
@export var effects: Array[ItemEffect] = []
## Stat id -> base value. Stats not listed use StatIds.DEFAULTS.
@export var stat_overrides: Dictionary = {}
## Seconds of invulnerability after taking a hit.
@export var invulnerability_time: float = 0.5
@export var radius: float = 16.0

@export_group("Visual (placeholder)")
@export var color: Color = Color(0.85, 0.95, 1.0)
## Sprite sheet id in assets/sprites/ (empty: placeholder circle).
@export var sprite_id: StringName
