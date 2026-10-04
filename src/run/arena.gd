class_name Arena
extends Node2D
## Arena art (tools/art/make_map.py + AI decor, docs/design/art-bible.md): tiled
## dungeon stone slabs, flat decals scattered on the floor (no collision, low
## contrast), a low stone wall on the border and tall props (pillars, braziers,
## crystals...) only outside the arena.
## Everything is drawn once (static canvas) from one ground texture and one
## decor atlas. Decor placement uses a fixed seed: same layout every run.

const GROUND := preload("res://assets/sprites/ground.png")
const DEFAULT_DECOR := preload("res://assets/map/decor_atlas.tres")
const WALL_THICKNESS := 26.0
## One floor decal per this many square pixels of arena (sparse: readability first).
const DECAL_AREA := 300000.0
## Decals stay this far from the arena center (player spawn) and from the walls.
const DECAL_CLEAR_CENTER := 260.0
const DECAL_MARGIN := 120.0
## Props outside the border: one every PROP_SPACING px, pushed out by PROP_OFFSET.
const PROP_SPACING := 230.0
const PROP_OFFSET := 70.0
const DECOR_SEED := 11

var rect: Rect2
## Look of the arena (null fields: default dungeon).
var biome: BiomeData
var _decor: DecorAtlas = DEFAULT_DECOR
var _ground_tint := Color.WHITE
var _outside := Color(0.12, 0.11, 0.18)
var _wall := Color(0.25, 0.23, 0.34)
var _border := Color(0.62, 0.58, 0.78)
var _decals: Array[Array] = []  # [name, position, rotation, alpha]
var _props: Array[Array] = []  # [name, foot position]


func setup(p_rect: Rect2, p_biome: BiomeData = null) -> void:
	rect = p_rect
	biome = p_biome
	if biome != null:
		if biome.decor != null:
			_decor = biome.decor
		_ground_tint = biome.ground_tint
		_outside = biome.outside_color
		_wall = biome.wall_color
		_border = biome.border_color
	z_index = -10
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_place_decor()
	var gates := ArenaGates.new()
	gates.setup(rect, biome.gate_color if biome != null else ArenaGates.DEFAULT_COLOR)
	add_child(gates)
	queue_redraw()


func decal_count() -> int:
	return _decals.size()


func prop_count() -> int:
	return _props.size()


func _place_decor() -> void:
	_decals.clear()
	_props.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = DECOR_SEED
	var decal_names := _decor.names_with("decal_")
	var prop_names := _decor.names_with("prop_")
	if decal_names.is_empty() or prop_names.is_empty():
		return
	var inner := rect.grow(-DECAL_MARGIN)
	var wanted := int(rect.get_area() / DECAL_AREA)
	var attempts := 0
	while _decals.size() < wanted and attempts < wanted * 10:
		attempts += 1
		var pos := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		if pos.distance_to(rect.get_center()) < DECAL_CLEAR_CENTER:
			continue
		var name: StringName = decal_names[rng.randi_range(0, decal_names.size() - 1)]
		_decals.append([name, pos, rng.randf_range(-0.5, 0.5), rng.randf_range(0.55, 0.85)])
	# Props along the four sides, just outside the wall, feet on the outer ground.
	var sides: Array[Array] = [
		[rect.position + Vector2(0, -PROP_OFFSET), Vector2.RIGHT, rect.size.x],
		[rect.position + Vector2(0, rect.size.y + PROP_OFFSET * 2.2), Vector2.RIGHT, rect.size.x],
		[rect.position + Vector2(-PROP_OFFSET, 0), Vector2.DOWN, rect.size.y],
		[rect.position + Vector2(rect.size.x + PROP_OFFSET, 0), Vector2.DOWN, rect.size.y],
	]
	for side in sides:
		var start: Vector2 = side[0]
		var direction: Vector2 = side[1]
		var length: float = side[2]
		var d := rng.randf_range(20.0, PROP_SPACING)
		while d < length:
			var name: StringName = prop_names[rng.randi_range(0, prop_names.size() - 1)]
			_props.append([name, start + direction * d])
			d += PROP_SPACING * rng.randf_range(0.7, 1.3)
	# Draw order: farther (higher) props first.
	_props.sort_custom(func(a: Array, b: Array) -> bool: return a[1].y < b[1].y)


func _draw() -> void:
	draw_rect(rect.grow(2400.0), _outside)
	draw_texture_rect(GROUND, rect, true, _ground_tint)
	var texture := _decor.texture
	for decal in _decals:
		var region: Rect2 = _decor.regions[decal[0]]
		draw_set_transform(decal[1], decal[2])
		draw_texture_rect_region(texture, Rect2(-region.size * 0.5, region.size), region, Color(1, 1, 1, decal[3]))
	draw_set_transform(Vector2.ZERO)
	# Low wall: dark stone band outside the floor, lighter worn top edge.
	draw_rect(rect.grow(WALL_THICKNESS), _wall, false, WALL_THICKNESS * 2.0)
	draw_rect(rect.grow(WALL_THICKNESS * 0.5), Color(_border, 0.12), false, 30.0)
	draw_rect(rect, Color(_border, 0.3), false, 12.0)
	draw_rect(rect, _border, false, 4.0)
	for prop in _props:
		var region: Rect2 = _decor.regions[prop[0]]
		var foot: Vector2 = prop[1]
		draw_texture_rect_region(texture, Rect2(foot - Vector2(region.size.x * 0.5, region.size.y), region.size), region)
