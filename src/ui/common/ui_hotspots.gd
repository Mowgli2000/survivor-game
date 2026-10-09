class_name UiHotspots
extends Control
## Interactive painting over a background picture: flames, crystals and the floor seal. A flame
## under the mouse comes alive (a frame-by-frame animation drawn in the pictures' style, with a fire
## crackle sound). The painting
## itself shines more when hovered (ui_hotspot_glow.gdshader re-draws a region of the picture):
## a crystal glows bluer with a soft bloom, the seal's lines blink slowly. Display only; idle,
## nothing is drawn. The picture's screen rectangle comes from `picture_rect` (it may drift).

enum Kind { CRYSTAL, SEAL, FLAME }

const FLAME_SHADER := preload("res://src/ui/character_select/ui_flame_anim.gdshader")
const FLAME_SHEET := preload("res://assets/ui/select/flame_sheet.png")
## The animated flame fills this share of its cell's height (the cell is square, 384 x 384 on the
## sheet's 4 x 2 grid of 384 x 512 cells: the cell is cut to the flame's own proportions).
const FLAME_HEIGHT_FILL := 0.86
## The animation is a little bigger than the painted flame so it covers it (dev: +8 %).
const FLAME_GROW := 1.08
## Painted flames of the gate pictures (measured on the pictures): base of the flame on the rim of
## its brazier (share of the picture) and its height as a share of the picture's width; the last
## number squeezes the animated flame sideways for the thin ones.
const GATE_FLAMES: Array = [
	[Vector2(0.256, 0.545), 0.061, 1.0], [Vector2(0.746, 0.543), 0.061, 1.0],
	[Vector2(0.319, 0.623), 0.029, 1.0], [Vector2(0.681, 0.623), 0.029, 1.0],
	[Vector2(0.196, 0.608), 0.034, 0.75], [Vector2(0.885, 0.612), 0.034, 0.75],
	[Vector2(0.797, 0.607), 0.026, 0.8]]
## The two small flames at the back of the hunters' hall (not in the seal gate picture).
const BACK_FLAMES: Array = [[Vector2(0.421, 0.52), 0.024, 1.0], [Vector2(0.576, 0.52), 0.024, 1.0]]
## The tiny flame on top of the post, right of the seal gate picture.
const POST_FLAME: Array = [Vector2(0.848, 0.488), 0.014, 0.8]
const FIRE_LOOP := &"hotspot_fire"
const FIRE_DB := -9.0
const GLOW_SHADER := preload("res://src/ui/character_select/ui_hotspot_glow.gdshader")
## Share of the spot's radius where the hover starts.
const HOVER_REACH := 1.5
const EASE_SPEED := 7.0

## Returns the picture's rectangle on screen (Callable() -> Rect2).
var picture_rect: Callable
## The painting (the crystal and seal regions are cut from it).
var texture: Texture2D

var _spots: Array[Dictionary] = []
var _crystal_layer: Layer
var _seal_layer: Layer
var _glow_was_on: bool = false


## A layer whose drawing is delegated, with its own material.
class Layer extends Control:
	var draw_function: Callable

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if draw_function.is_valid():
			draw_function.call(self)


## Puts a living flame on each painted flame of a gate picture. `hall`: the hunters' hall (two
## extra flames at the back) or the seal gate (one extra tiny flame on a post).
func add_gate_flames(color: Color, hall: bool) -> void:
	var list: Array = GATE_FLAMES.duplicate()
	list.append_array(BACK_FLAMES if hall else [POST_FLAME])
	for entry in list:
		add_spot(Kind.FLAME, entry[0], entry[1], color, entry[2])


## `uv`: position in the picture (0..1); `radius`: share of the picture's width (a flame: the
## painted flame's HEIGHT, `uv` is its base); `ratio`: a seal's height / width, a flame's sideways
## squeeze. A flame's `color` decides blue or violet.
func add_spot(kind: Kind, uv: Vector2, radius: float, color: Color, ratio: float = 1.0) -> void:
	var spot := {"kind": kind, "uv": uv, "radius": radius, "color": color, "ratio": ratio,
		"level": 0.0, "phase": fposmod(uv.x * 91.7 + uv.y * 37.3, 1.0), "node": null}
	if kind == Kind.FLAME:
		var quad := ColorRect.new()
		quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var flame_material := ShaderMaterial.new()
		flame_material.shader = FLAME_SHADER
		flame_material.set_shader_parameter(&"sheet", FLAME_SHEET)
		flame_material.set_shader_parameter(&"seed", spot["phase"])
		flame_material.set_shader_parameter(&"violet", 1.0 if color.r > color.g else 0.0)
		flame_material.set_shader_parameter(&"level", 0.0)
		quad.material = flame_material
		quad.visible = false
		add_child(quad)
		spot["node"] = quad
	_spots.append(spot)


func spot_count() -> int:
	return _spots.size()


## Hover level (0..1) of spot `index` (tests).
func level_of(index: int) -> float:
	return _spots[index]["level"]


func _ready() -> void:
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree():
			Audio.loop_stop(FIRE_LOOP))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_crystal_layer = _make_layer(0, 1.5, 0.55, 0.8)
	_seal_layer = _make_layer(1, 1.25, 0.4, 0.7)


func _make_layer(mode: int, gain: float, light_low: float, light_high: float) -> Layer:
	var layer := Layer.new()
	var shader_material := ShaderMaterial.new()
	shader_material.shader = GLOW_SHADER
	shader_material.set_shader_parameter(&"mode", mode)
	shader_material.set_shader_parameter(&"gain", gain)
	shader_material.set_shader_parameter(&"light_low", light_low)
	shader_material.set_shader_parameter(&"light_high", light_high)
	layer.material = shader_material
	layer.draw_function = _draw_regions.bind(mode)
	add_child(layer)
	return layer


func _process(delta: float) -> void:
	if not is_visible_in_tree() or not picture_rect.is_valid():
		return
	var rect: Rect2 = picture_rect.call()
	if rect.size.x <= 0.0:
		return
	var mouse := get_global_mouse_position()
	var glowing := false
	var any_flame := false
	for spot in _spots:
		var target := 1.0 if _hovered(spot, rect, mouse) else 0.0
		var level: float = spot["level"]
		level = target if UiFx.reduce_motion else move_toward(level, target, delta * EASE_SPEED)
		spot["level"] = level
		if spot["kind"] == Kind.FLAME:
			_place_flame(spot, rect, level)
			any_flame = any_flame or target > 0.0
		else:
			glowing = glowing or level > 0.0
	# The fire burns (a looping sound) for as long as the mouse is on a flame, then fades.
	if any_flame:
		Audio.loop_start(FIRE_LOOP, Sounds.FIRE_CRACKLE, FIRE_DB)
	else:
		Audio.loop_stop(FIRE_LOOP)
	# The glow layers redraw while a crystal or the seal is lit (and once more when it fades).
	if glowing or _glow_was_on:
		_crystal_layer.queue_redraw()
		_seal_layer.queue_redraw()
	_glow_was_on = glowing


func _hovered(spot: Dictionary, rect: Rect2, mouse: Vector2) -> bool:
	var center: Vector2 = rect.position + (spot["uv"] as Vector2) * rect.size
	var radius: float = spot["radius"] * rect.size.x * HOVER_REACH
	if spot["kind"] == Kind.FLAME:
		radius = spot["radius"] * rect.size.x * 0.5
	var offset := mouse - center
	if spot["kind"] == Kind.SEAL:
		offset.y /= maxf(spot["ratio"], 0.05)
	elif spot["kind"] == Kind.FLAME:
		offset.y += radius * 0.8  # the flame stands above its base
	return offset.length() <= radius


## A flame stands on its base (uv); the animated cell is put so its own flame covers the painted one.
func _place_flame(spot: Dictionary, rect: Rect2, level: float) -> void:
	var quad: ColorRect = spot["node"]
	quad.visible = level > 0.0
	if level <= 0.0:
		return
	var height: float = spot["radius"] * rect.size.x / FLAME_HEIGHT_FILL * FLAME_GROW
	var width := height * float(spot["ratio"])
	var base: Vector2 = rect.position + (spot["uv"] as Vector2) * rect.size
	quad.size = Vector2(width, height)
	# The flame's base is at ~98 % of the cell's height.
	quad.position = base - Vector2(width * 0.5, height * 0.985)
	(quad.material as ShaderMaterial).set_shader_parameter(&"level", level)


## The part of the picture (in uv) a crystal or the seal re-draws.
func region_of(spot: Dictionary) -> Rect2:
	var uv: Vector2 = spot["uv"]
	var r: float = spot["radius"]
	# A share of the picture's width, seen on the picture's height.
	var tall := 1.5 if texture == null else texture.get_width() / float(texture.get_height())
	if spot["kind"] == Kind.CRYSTAL:
		return Rect2(uv.x - r * 1.5, uv.y - r * 2.6 * tall, r * 3.0, r * 5.2 * tall)
	var ratio: float = spot["ratio"]
	return Rect2(uv.x - r * 1.12, uv.y - r * ratio * 1.3 * tall, r * 2.24, r * ratio * 2.6 * tall)


func _draw_regions(layer: Layer, mode: int) -> void:
	if texture == null or not picture_rect.is_valid():
		return
	var rect: Rect2 = picture_rect.call()
	var size_px := Vector2(texture.get_size())
	for spot in _spots:
		var level: float = spot["level"]
		var kind: int = spot["kind"]
		if level <= 0.01 or kind == Kind.FLAME or (kind == Kind.SEAL) != (mode == 1):
			continue
		var region := region_of(spot)
		var dest := Rect2(rect.position + region.position * rect.size, region.size * rect.size)
		var source := Rect2(region.position * size_px, region.size * size_px)
		layer.draw_texture_rect_region(texture, dest, source, Color(spot["phase"], 0.0, 0.0, level))
