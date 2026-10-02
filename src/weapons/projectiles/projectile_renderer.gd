class_name ProjectileRenderer
extends MultiMeshInstance2D
## Draws a list of Projectile data in a single draw call, as additive "neon"
## glows (measured: 1000 node-based projectiles cost ~2/3 of the frame, ADR 0004).

var _stretch: float
var _glow: float


## `stretch`: length / width ratio along the velocity. `glow`: halo size vs. hitbox.
func _init(stretch: float = 1.8, glow: float = 1.8) -> void:
	_stretch = stretch
	_glow = glow
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh.mesh = quad
	multimesh.instance_count = 256
	multimesh.visible_instance_count = 0
	texture = _make_glow_texture()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func render(projectiles: Array[Projectile]) -> void:
	var count := projectiles.size()
	if count > multimesh.instance_count:
		# Grow in steps; resizing clears the buffer, but it is fully rewritten below.
		multimesh.instance_count = maxi(count, multimesh.instance_count * 2)
	multimesh.visible_instance_count = count
	for i in count:
		var p := projectiles[i]
		var size := p.radius * 2.0 * _glow
		multimesh.set_instance_transform_2d(i,
			Transform2D(p.velocity.angle(), Vector2(size * _stretch, size), 0.0, p.position))
		multimesh.set_instance_color(i, p.color)


static func _make_glow_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.4, 0.6, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 32
	texture.height = 32
	return texture
