class_name ProjectileRenderer
extends MultiMeshInstance2D
## Draws a list of Projectile data in two draw calls (ADR 0004, 0016): plain
## projectiles as additive neon glows (this node), styled ones (orb, bullet,
## missile, shuriken...) as solid bodies from one strip texture, the cell
## picked per instance by a shader.

const BODY_TEXTURE := preload("res://assets/sprites/projectiles.png")
const BODY_SHADER := preload("res://src/weapons/projectiles/projectile_body.gdshader")
const BODY_CELLS := 101
## Columns of the grid atlas (tools/art/bake_map.gd PROJECTILE_COLUMNS); rows follow from the texture height (ADR 0028).
const BODY_COLUMNS := 16
## Styles drawn as a looping animation: Vector2i(strip cell of the first frame (0-based), number of frames).
## The loops come after the 23 style cells (tools/art/bake_proj.py). The energy shots and the bomb have 12 frames (as the melee
## swings), the grenade 6.
const ANIM := {
	WeaponData.ProjectileStyle.BOMB: Vector2i(23, 12), WeaponData.ProjectileStyle.FIREBALL: Vector2i(35, 12),
	WeaponData.ProjectileStyle.LIGHTNING: Vector2i(47, 12), WeaponData.ProjectileStyle.ORB: Vector2i(59, 12),
	WeaponData.ProjectileStyle.GRENADE: Vector2i(71, 6), WeaponData.ProjectileStyle.SHADOW_BLADE: Vector2i(77, 12),
	WeaponData.ProjectileStyle.STONE: Vector2i(89, 12),
}
## Seconds one pass of a loop lasts, whatever its number of frames (so 12 frames play at 26 fps, 6 at 13 fps).
const ANIM_CYCLE := 0.46
## Lobbed styles spin on themselves in flight, radians per second.
const LOB_SPIN := {
	WeaponData.ProjectileStyle.BOMB: 3.0, WeaponData.ProjectileStyle.FIRE_FLASK: 7.0,
	WeaponData.ProjectileStyle.FROST_FLASK: 7.0, WeaponData.ProjectileStyle.GRENADE: 6.0,
	WeaponData.ProjectileStyle.CANNONBALL: 4.0, WeaponData.ProjectileStyle.BOMB_FLASK: 7.0,
	WeaponData.ProjectileStyle.ORB: 4.0,
}
## Cell index code in the body color's alpha (see projectile_body.gdshader).
const CELL_CODE := 256.0
## Per style (index = WeaponData.ProjectileStyle): length of the square art cell
## vs. the hitbox diameter (painted projectiles: the head sits at the right of a long trail, so
## their cells are about 2.4 times bigger than the old code-drawn ones). The art (AI, pointing right, trail on the left) keeps
## its own proportions inside the cell and its own colors (no tint).
const BODY_SCALE: Array[float] = [0.0, 2.8, 3.2, 10.0, 9.5, 1.25, 3.6, 6.4, 9.5, 8.0, 12.0, 10.0, 12.0,
	2.6, 3.75, 3.75, 3.0, 3.7, 3.6, 3.6, 3.6, 3.6, 11.0, 3.4, 2.1]
## Shuriken spin, radians per second of flight.
const SPIN_SPEED := 18.0

## Per cell: height of the used band (centered) vs. the cell, measured once from
## the texture. The body quad is that much flatter: far less transparent overdraw.
static var _band: PackedFloat32Array = PackedFloat32Array()
## Per looping style: the largest band of its frames. One band for the whole loop: a band that changes from frame to
## frame resized the quad and made the sprite pulse once per cycle (the fireball).
static var _loop_band: Dictionary = {}

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
	body_material.set_shader_parameter("columns", float(BODY_COLUMNS))
	body_material.set_shader_parameter("rows", float(BODY_TEXTURE.get_height()) * BODY_COLUMNS / BODY_TEXTURE.get_width())
	_body.material = body_material
	add_child(_body)
	if _band.is_empty():
		_band = measure_bands(BODY_TEXTURE, BODY_CELLS)
		for style: int in ANIM:
			var loop: Vector2i = ANIM[style]
			var widest := 0.0
			for k in loop.y:
				widest = maxf(widest, _band[loop.x + k])
			_loop_band[style] = widest


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
		var angle := p.velocity.angle()
		var position := p.position
		if style == WeaponData.ProjectileStyle.SHURIKEN:
			angle = (_time + p.life) * SPIN_SPEED
		elif p.fused:
			angle = 0.0  # a bomb at rest stands upright, fuse up (as painted)
		elif p.lob_peak > 0.0:
			# A lobbed shot: spins on itself, rises and falls in an arc over the ground point.
			angle = (_time + p.life) * LOB_SPIN.get(style, 5.0)
			var flown := 1.0 - p.life / p.lob_total
			position.y -= 4.0 * p.lob_peak * flown * (1.0 - flown)
		var cell := style - 1
		var next := cell
		var blend := 0.0
		if ANIM.has(style):
			# Loop of painted frames, cross-faded by the shader (a few frames read as a smooth flow).
			var loop: Vector2i = ANIM[style]
			var frame := (_time + p.life * 0.37) * loop.y / ANIM_CYCLE
			var whole := int(frame)
			blend = frame - whole
			cell = loop.x + posmod(whole, loop.y)
			next = loop.x + posmod(whole + 1, loop.y)
		var band: float = _loop_band[style] if ANIM.has(style) else _band[cell]
		_body.multimesh.set_instance_transform_2d(bodies,
			Transform2D(angle, Vector2(body, body * band), 0.0, position))
		# Red carries the band to the shader (the art is not tinted), green the cross-fade weight, blue the next frame.
		var tint := Color(band, blend, (next + 0.5) / CELL_CODE, (cell + 0.5) / CELL_CODE)
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
	var cell := image.get_width() / BODY_COLUMNS
	for c in cells:
		var used := image.get_region(Rect2i((c % BODY_COLUMNS) * cell, (c / BODY_COLUMNS) * cell, cell, cell)).get_used_rect()
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
