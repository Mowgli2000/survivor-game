class_name SkinData
extends Resource
## A cosmetic look for one class, bought in the skin shop with portal shards
## (ADR 0023). Same class, rules and stats as the character: only the picture changes.
## Instances live in data/skins/.

@export var id: StringName
@export var name_key: String
## The class (CharacterData.id) it belongs to.
@export var character_id: StringName
## 1 = same outfit in other colors, 2 = more visual change, 3 = prestige (almost a new
## hero). Colors the card like item tiers (gray / blue / purple).
@export_range(1, 3) var rarity: int = 1
## Price in portal shards (guide: I 150-250, II 350-500, III 700-1000).
@export var price: int = 100
## Seal (difficulty level) that must have been won, with any hunter, before the skin can be
## bought; -1 = none. Prestige skins ask for the Astral seal (5).
@export var required_seal: int = -1
## Selection card (the big picture on the turntable), like CharacterData.card_art.
@export var card_art: Texture2D
## Sprite in the SpriteSheet atlas (the in-run look) and its scale.
@export var sprite_id: StringName
@export var sprite_scale: float = 1.0


## Problems with the data (empty when valid). Checked by the content tests.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if id == &"" or name_key == "" or character_id == &"":
		problems.append("id, name_key and character_id are required")
	if price < 0:
		problems.append("negative price")
	if rarity < 1 or rarity > 3:
		problems.append("rarity must be 1..3")
	if sprite_id == &"":
		problems.append("sprite_id is missing")
	return problems
