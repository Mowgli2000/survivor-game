shader_type canvas_item;
// Projectile bodies (ProjectileRenderer, renderer: Compatibility): each
// MultiMesh instance picks one cell of the horizontal strip
// assets/sprites/projectiles.png. The cell index travels in the instance
// color's alpha (alpha = (cell + 0.5) / CELL_CODE), so the renderer sets only
// a transform and a color per instance; the body is then drawn opaque.
// Vertex-only work, one texture sample: cheap for 1000+ projectiles.

// Number of cells in the strip (one per WeaponData.ProjectileStyle except GLOW).
uniform float cells : hint_range(1.0, 64.0) = 6.0;
// Must match ProjectileRenderer.CELL_CODE.
const float CELL_CODE = 8.0;

void vertex() {
	float cell = floor(COLOR.a * CELL_CODE);
	UV.x = (UV.x + cell) / cells;
	COLOR.a = 1.0;
}
