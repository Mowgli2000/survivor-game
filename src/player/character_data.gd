class_name CharacterData
extends Resource
## Definition of a playable character. Instances live in data/characters/.

@export var id: StringName
@export var name_key: String
@export var starting_weapon: WeaponData
## Stat id -> base value. Stats not listed use StatIds.DEFAULTS.
@export var stat_overrides: Dictionary = {}
## Seconds of invulnerability after taking a hit.
@export var invulnerability_time: float = 0.5
@export var radius: float = 16.0

@export_group("Visual (placeholder)")
@export var color: Color = Color(0.85, 0.95, 1.0)
## Sprite sheet id in assets/sprites/ (empty: placeholder circle).
@export var sprite_id: StringName
