class_name BiomeData
extends Resource
## Where a seal's gate leads (ADR 0018): arena look and bestiary. The stage keeps
## its curves and wave structure; the biome only swaps which monsters and bosses
## play each role and how the arena looks. Instances live in data/biomes/.

@export var id: StringName
@export var name_key: String

@export_group("Bestiary")
## Base enemy id (the default stage's role: &"grunt", &"ronin"...) -> this biome's
## monster for that role. Roles not listed keep the base monster.
@export var enemy_swaps: Dictionary[StringName, EnemyData] = {}

@export_group("Arena")
## Decor of the arena (null: the default dungeon decor).
@export var decor: DecorAtlas
## Multiplies the floor texture (warm sandstone, frost...).
@export var ground_tint: Color = Color.WHITE
@export var outside_color: Color = Color(0.12, 0.11, 0.18)
@export var wall_color: Color = Color(0.25, 0.23, 0.34)
@export var border_color: Color = Color(0.62, 0.58, 0.78)
## Color of the gates at the arena border.
@export var gate_color: Color = Color(0.64, 0.35, 1.0)


## This biome's monster for `enemy`'s role (or `enemy` itself).
func swap(enemy: EnemyData) -> EnemyData:
	if enemy == null:
		return null
	return enemy_swaps.get(enemy.id, enemy)
