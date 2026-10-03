class_name DecorAtlas
extends Resource
## Arena decor packed in one texture (tools/art/bake_map.gd): every decal and
## prop is a region, so the whole decor draws with a single texture.

@export var texture: Texture2D
## Decor name ("decal_manhole", "prop_lantern"...) -> region in `texture`.
@export var regions: Dictionary[StringName, Rect2] = {}


## Names starting with `prefix` ("decal_" or "prop_"), sorted.
func names_with(prefix: String) -> Array[StringName]:
	var names: Array[StringName] = []
	for name in regions:
		if String(name).begins_with(prefix):
			names.append(name)
	names.sort()
	return names
