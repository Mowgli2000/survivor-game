class_name UiBackdrop
extends Control
## Full-screen themed backdrop (menus, shop, level-up...): a painted background drawn "cover"
## style, slowly drifting and breathing, a dark vignette and a few drifting crystal sparks.
## Display only; stops animating when hidden or when reduce_motion is on.

const SPARK_COUNT := 34
const SPARK_COLOR := Color("8fe3ff")
const DRIFT_PERIOD := 0.06

var texture: Texture2D
## Dark overlay over the picture (0 = raw painting).
var dim: float = 0.25
## Base zoom of the picture (1 = just covers the screen) and a shift in pixels (at 1080p)
## to put a part of the painting where the screen needs it.
var base_zoom: float = 1.07
var shift: Vector2 = Vector2.ZERO
var sparks_enabled: bool = true
## False: a still picture (no drift, no zoom breathing, no sparks).
var animated: bool = true
## How much the vignette darkens the edges (0..1).
var vignette: float = 0.55

## Where the picture was drawn on screen at the last redraw (drift and zoom included).
var _picture_rect := Rect2()
var _time: float = 0.0
## x fraction, phase, size, speed
var _sparks: Array[Vector4] = []
var _vignette_texture: GradientTexture2D


static func create(background: Texture2D, dim_amount: float = 0.25) -> UiBackdrop:
	var backdrop := UiBackdrop.new()
	backdrop.texture = background
	backdrop.dim = dim_amount
	return backdrop


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Under a CanvasLayer there is no parent Control to anchor to: follow the viewport.
	if get_parent() is Control:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		_fit_viewport()
		get_viewport().size_changed.connect(_fit_viewport)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in SPARK_COUNT:
		_sparks.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(2.5, 6.5), rng.randf_range(0.012, 0.035)))
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(0.0, 0.01, 0.05, 1.0))
	gradient.add_point(0.55, Color(0, 0, 0, 0))
	_vignette_texture = GradientTexture2D.new()
	_vignette_texture.gradient = gradient
	_vignette_texture.fill = GradientTexture2D.FILL_RADIAL
	_vignette_texture.fill_from = Vector2(0.5, 0.5)
	_vignette_texture.fill_to = Vector2(1.0, 0.85)
	_vignette_texture.width = 128
	_vignette_texture.height = 128


## The picture's rectangle in this control's coordinates (for UiHotspots).
func picture_rect() -> Rect2:
	return Rect2(global_position + _picture_rect.position, _picture_rect.size)


func _fit_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size


func _process(delta: float) -> void:
	if not animated or UiFx.reduce_motion or not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if texture != null:
		var cover := maxf(size.x / texture.get_width(), size.y / texture.get_height())
		var zoom := base_zoom + 0.015 * sin(_time * 0.11)
		var draw_size := Vector2(texture.get_size()) * cover * zoom
		var drift := Vector2(sin(_time * DRIFT_PERIOD * TAU) * 18.0, cos(_time * DRIFT_PERIOD * 0.7 * TAU) * 9.0)
		_picture_rect = Rect2((size - draw_size) * 0.5 + drift + shift * (size.y / 1080.0), draw_size)
		draw_texture_rect(texture, _picture_rect, false)
	if dim > 0.0:
		draw_rect(rect, Color(0.0, 0.01, 0.05, dim))
	if vignette > 0.0:
		draw_texture_rect(_vignette_texture, rect, false, Color(1, 1, 1, vignette))
	if sparks_enabled:
		_draw_sparks()


func _draw_sparks() -> void:
	for spark in _sparks:
		var rise := fposmod(spark.y + _time * spark.w, 1.0)
		var pos := Vector2(
			spark.x * size.x + sin(_time * 0.5 + spark.y * TAU) * 24.0,
			size.y * (1.05 - rise * 1.1))
		var twinkle := 0.45 + 0.55 * sin(_time * 1.7 + spark.x * 20.0)
		var fade := minf(rise * 6.0, 1.0) * minf((1.0 - rise) * 4.0, 1.0)
		var color := Color(SPARK_COLOR, 0.8 * twinkle * fade)
		var r := spark.z
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(0, -r * 1.8), pos + Vector2(r, 0), pos + Vector2(0, r * 1.8), pos + Vector2(-r, 0)]), color)
		draw_circle(pos, r * 2.4, Color(color, color.a * 0.12))
