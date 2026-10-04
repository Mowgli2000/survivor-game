class_name CharacterData
extends Resource
## Definition of a playable character. Instances live in data/characters/.

## Weapons the character may get from the shop (docs/design/classes-proposition.md).
enum WeaponKind { ANY, MELEE, RANGED }

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
@export_group("Class rules")
## Restricts the shop's weapons (and the starting weapons, by design).
@export var weapon_kind: WeaponKind = WeaponKind.ANY
## Multiplies the level-up cards (1.5 = +50 %).
@export var upgrade_scale: float = 1.0
## Multiplies the shop prices (0.8 = -20 %).
@export var shop_price_multiplier: float = 1.0
## Multiplies the reroll costs (shop and level-up cards).
@export var reroll_cost_multiplier: float = 1.0
@export_group("")
## Seconds of invulnerability after taking a hit.
@export var invulnerability_time: float = 0.5
@export var radius: float = 16.0

@export_group("Visual (placeholder)")
@export var color: Color = Color(0.85, 0.95, 1.0)
## Sprite sheet id in assets/sprites/ (empty: placeholder circle).
@export var sprite_id: StringName
## On-screen size of the sprite (1 = the standard character height). Gameplay radius unchanged.
@export var sprite_scale: float = 1.0
## Detailed illustration shown on the character select card (null: the animated sprite).
@export var card_art: Texture2D


## True if the class rules let this character use `weapon`.
func allows_weapon(weapon: WeaponData) -> bool:
	match weapon_kind:
		WeaponKind.MELEE:
			return weapon.is_melee()
		WeaponKind.RANGED:
			return not weapon.is_melee()
	return true
