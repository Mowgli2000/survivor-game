class_name ProjectileRenderer
extends MultiMeshInstance2D
## Draws a list of Projectile data in two draw calls (ADR 0004, 0016): plain
## projectiles as additive neon glows (this node), styled ones (orb, bullet,
## missile, shuriken...) as solid bodies from one strip texture, the cell
## picked per instance by a shader.

const BODY_TEXTURE := preload("res://assets/sprites/projectiles.png")
const BODY_SHADER := preload("res://src/weapons/projectiles/projectile_body.gdshader")
const BODY_CELLS := 6
## Cell index code in the body color's alpha (see projectile_body.gdshader).
const CELL_CODE := 8.0
## Per style (index = WeaponData.ProjectileStyle): body length / width ratio,
## body size vs. hitbox, how much the projectile color tints the body.
const BODY_STRETCH: Array[float] = [1.0, 1.0, 1.9, 1.7, 2.0, 1.0, 1.0]
const BODY_SCALE: Array[float] = [0.0, 1.6, 2.2, 2.2, 1.7, 2.6, 1.6]
const BODY_TINT: Array[float] = [0.0, 1.0, 1.0, 0.0, 0.0, 0.25, 1.0]
## Shuriken spin, radians per second of flight.
const SPIN_SPEED := 18.0

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
	var body_material := ShaderMaterial.new()
	body_material.shader = BODY_SHADER
	body_material.set_shader_parameter("cells", float(BODY_CELLS))
	_body.material = body_material
	add_child(_body)


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
		_body.multimesh.set_instance_transform_2d(bodies,
			Transform2D(angle, Vector2(body * BODY_STRETCH[style], body), 0.0, p.position))
		var tint := Color.WHITE.lerp(p.color, BODY_TINT[style])
		tint.a = (style - 1 + 0.5) / CELL_CODE
		_body.multimesh.set_instance_color(bodies, tint)
		bodies += 1
	multimesh.visible_instance_count = glows
	_body.multimesh.visible_instance_count = bodies


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
