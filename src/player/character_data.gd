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
## Family the class is built around (Mage: &"energy"); weapons of other families
## deal `off_family_damage_scale` times their damage.
@export var favored_family: StringName = &""
@export var off_family_damage_scale: float = 1.0
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
## Articulated puppet (ADR 0020); replaces the baked sprite in game when set.
@export var rig: RigData
## Detailed illustration shown on the character select card (null: the animated sprite).
@export var card_art: Texture2D
@export_group("Second look (other sex)")
## Same class, rules and stats, another hero to pick at the start (variant 1).
## Empty `alt_sprite_id` = no second look.
@export var alt_name_key: String
@export var alt_sprite_id: StringName
@export var alt_sprite_scale: float = 1.0
@export var alt_card_art: Texture2D
@export_group("")


## True when the class has a second look (variant 1).
func has_alt_look() -> bool:
	return alt_sprite_id != &""


## Skins of this class the player bought (ADR 0023), cheapest first: the looks
## after the class's own one or two.
func owned_skins() -> Array[SkinData]:
	var skins: Array[SkinData] = []
	for def in ContentDB.get_all(&"skins"):
		var skin := def as SkinData
		if skin != null and skin.character_id == id and SaveService.profile.is_unlocked(&"skins", skin.id):
			skins.append(skin)
	skins.sort_custom(func(a: SkinData, b: SkinData) -> bool:
		return a.price < b.price or (a.price == b.price and a.id < b.id))
	return skins


## Looks that come with the class: the character and, if any, its second look.
func base_look_count() -> int:
	return 2 if has_alt_look() else 1


## Looks on the turntable: the base ones then the bought skins.
func look_count() -> int:
	return base_look_count() + owned_skins().size()


## The bought skin a `variant` index points at (null for the class's own looks).
func skin_for(variant: int) -> SkinData:
	var index := variant - base_look_count()
	if index < 0:
		return null
	var skins := owned_skins()
	return skins[index] if index < skins.size() else null


## `variant` 0 = the character itself, 1 = its second look (when it has one), then
## the bought skins.
func name_key_for(variant: int) -> String:
	var skin := skin_for(variant)
	if skin != null:
		return skin.name_key
	return alt_name_key if variant == 1 and has_alt_look() and alt_name_key != "" else name_key


func sprite_id_for(variant: int) -> StringName:
	var skin := skin_for(variant)
	if skin != null and skin.sprite_id != &"":
		return skin.sprite_id
	return alt_sprite_id if variant == 1 and has_alt_look() else sprite_id


func sprite_scale_for(variant: int) -> float:
	var skin := skin_for(variant)
	if skin != null:
		return skin.sprite_scale
	return alt_sprite_scale if variant == 1 and has_alt_look() else sprite_scale


func card_art_for(variant: int) -> Texture2D:
	var skin := skin_for(variant)
	if skin != null and skin.card_art != null:
		return skin.card_art
	return alt_card_art if variant == 1 and has_alt_look() and alt_card_art != null else card_art


## True if the class rules let this character use `weapon`.
func allows_weapon(weapon: WeaponData) -> bool:
	match weapon_kind:
		WeaponKind.MELEE:
			return weapon.is_melee()
		WeaponKind.RANGED:
			return not weapon.is_melee()
	return true
