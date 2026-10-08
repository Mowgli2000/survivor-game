class_name SkinData
extends Resource
## A cosmetic look for one class, bought in the skin shop with portal shards
## (ADR 0023). Same class, rules and stats as the character: only the picture changes.
## Instances live in data/skins/.

@export var id: StringName
@export var name_key: String
## The class (CharacterData.id) it belongs to.
@export var character_id: StringName
## Price in portal shards.
@export var price: int = 100
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
	if sprite_id == &"":
		problems.append("sprite_id is missing")
	return problems
