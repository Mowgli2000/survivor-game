class_name EnemyArt
## Bakes the placeholder neon look of an enemy type (dark body, neon outline,
## soft glow, anti-aliased edges) into a texture, once per EnemyData.
## Drawing one texture per enemy is a single, batchable command; drawing the
## same look with anti-aliased lines cost ~2/3 of the frame with 500 enemies.

const GLOW := 7.0
const OUTLINE := 3.0
const GLOW_ALPHA := 0.4
const BODY_DARKEN := 0.72


## Neon outline of elite enemies (gold, never used by a normal enemy type).
const ELITE_OUTLINE := Color(1.0, 0.8, 0.2)


static func bake(data: EnemyData, outline: Color, scale: float = 1.0) -> Texture2D:
	var radius := data.radius * scale
	var half := ceili(radius + GLOW) + 1
	var size := half * 2
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var body := data.color.darkened(BODY_DARKEN)
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5 - half, y + 0.5 - half)
			var d := _distance(p, data.shape_sides, radius)  # < 0 inside the shape
			var color: Color
			if d <= -OUTLINE:
				color = body
			elif d <= 0.0:
				# Outline band, blended into the body over 1 px.
				color = body.lerp(outline, clampf((d + OUTLINE) + 0.5, 0.0, 1.0))
			else:
				var glow := GLOW_ALPHA * pow(clampf(1.0 - d / GLOW, 0.0, 1.0), 2.0)
				var edge := clampf(1.0 - d, 0.0, 1.0)  # anti-aliased shape edge
				color = Color(outline, maxf(edge, glow))
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


## Signed distance from `p` to the shape (circle, or regular polygon with a
## vertex pointing right, like the enemy's facing direction).
static func _distance(p: Vector2, sides: int, radius: float) -> float:
	if sides < 3:
		return p.length() - radius
	var apothem := radius * cos(PI / sides)
	var result := -INF
	for k in sides:
		var normal := Vector2.from_angle((k + 0.5) * TAU / sides)
		result = maxf(result, p.dot(normal) - apothem)
	return result
