class_name ProjectileRenderer
extends MultiMeshInstance2D
## Draws a list of Projectile data in two draw calls (ADR 0004, 0016): plain
## projectiles as additive neon glows (this node), styled ones (orb, bullet,
## missile, shuriken...) as solid bodies from one strip texture, the cell
## picked per instance by a shader.

const BODY_TEXTURE := preload("res://assets/sprites/projectiles.png")
const BODY_SHADER := preload("res://src/weapons/projectiles/projectile_body.gdshader")
const BODY_CELLS := 21
## Cell index code in the body color's alpha (see projectile_body.gdshader).
const CELL_CODE := 32.0
## Per style (index = WeaponData.ProjectileStyle): length of the square art cell
## vs. the hitbox diameter. The art (AI, pointing right, trail on the left) keeps
## its own proportions inside the cell and its own colors (no tint).
const BODY_SCALE: Array[float] = [0.0, 4.0, 4.0, 4.5, 4.0, 4.0, 3.6, 4.2, 4.0, 4.0, 6.0, 3.2, 6.0,
	3.0, 4.0, 4.0, 3.6, 3.6, 3.6, 3.6, 3.6, 3.6]
## Shuriken spin, radians per second of flight.
const SPIN_SPEED := 18.0

## Per cell: height of the used band (centered) vs. the cell, measured once from
## the texture. The body quad is that much flatter: far less transparent overdraw.
static var _band: PackedFloat32Array = PackedFloat32Array()

var _stretch: float
var _glow: float
var _body: MultiMeshInstance2D
var _time: float = 0.0


## `stretch`: length / width ratio along the velocity. `glow`: halo size vs. hitbox.
func _init(stretch: float = 1.8, glow: float = 1.8) -> void:
	_stretch = stretch
	_glow = glow
	multimesh = _make_multimesh()
	texture = _make_glow_texture()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	_body = MultiMeshInstance2D.new()
	_body.multimesh = _make_multimesh()
	_body.texture = BODY_TEXTURE
	# 128 px cells drawn at 20-60 px: mipmaps keep them crisp and cheap to sample.
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var body_material := ShaderMaterial.new()
	body_material.shader = BODY_SHADER
	body_material.set_shader_parameter("cells", float(BODY_CELLS))
	_body.material = body_material
	add_child(_body)
	if _band.is_empty():
		_band = measure_bands(BODY_TEXTURE, BODY_CELLS)


func body_count() -> int:
	return _body.multimesh.visible_instance_count


func render(projectiles: Array[Projectile]) -> void:
	_time += get_process_delta_time()
	var count := projectiles.size()
	_grow(multimesh, count)
	_grow(_body.multimesh, count)
	# Styled projectiles are drawn by their body only, plain ones by the glow:
	# two setter calls per projectile either way (measured: per-instance
	# setters beat filling float buffers from GDScript).
	var glows := 0
	var bodies := 0
	for i in count:
		var p := projectiles[i]
		var style := p.style
		if style == 0:
			var size := p.radius * 2.0 * _glow
			multimesh.set_instance_transform_2d(glows,
				Transform2D(p.velocity.angle(), Vector2(size * _stretch, size), 0.0, p.position))
			multimesh.set_instance_color(glows, p.color)
			glows += 1
			continue
		var body := p.radius * 2.0 * BODY_SCALE[style]
		var angle := (_time + p.life) * SPIN_SPEED if style == WeaponData.ProjectileStyle.SHURIKEN 			else p.velocity.angle()
		var band := _band[style - 1]
		_body.multimesh.set_instance_transform_2d(bodies,
			Transform2D(angle, Vector2(body, body * band), 0.0, p.position))
		# Red carries the band to the shader (the art is not tinted).
		var tint := Color(band, 1.0, 1.0, (style - 1 + 0.5) / CELL_CODE)
		_body.multimesh.set_instance_color(bodies, tint)
		bodies += 1
	multimesh.visible_instance_count = glows
	_body.multimesh.visible_instance_count = bodies


## Used height of each square cell of `texture`, symmetric around the middle (0..1].
static func measure_bands(texture: Texture2D, cells: int) -> PackedFloat32Array:
	var bands := PackedFloat32Array()
	bands.resize(cells)
	bands.fill(1.0)
	var image := texture.get_image()
	if image == null:
		return bands
	if image.is_compressed():
		image.decompress()
	var cell := image.get_height()
	for c in cells:
		var used := image.get_region(Rect2i(c * cell, 0, cell, cell)).get_used_rect()
		if used.size.y <= 0:
			continue
		var half := maxf(cell * 0.5 - used.position.y, used.end.y - cell * 0.5)
		bands[c] = clampf(half * 2.0 / cell + 0.04, 0.1, 1.0)
	return bands


## Grows in steps; resizing clears the buffer, but render() rewrites what it shows.
static func _grow(mm: MultiMesh, count: int) -> void:
	if count > mm.instance_count:
		mm.instance_count = maxi(count, mm.instance_count * 2)


static func _make_multimesh() -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mm.mesh = quad
	mm.instance_count = 256
	mm.visible_instance_count = 0
	return mm


static func _make_glow_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.4, 0.6, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var glow_texture := GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(1.0, 0.5)
	glow_texture.width = 32
	glow_texture.height = 32
	return glow_texture
