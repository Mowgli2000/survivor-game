shader_type canvas_item;
// Projectile bodies (ProjectileRenderer, renderer: Compatibility): each
// MultiMesh instance picks one cell of the grid
// assets/sprites/projectiles.png (columns x rows of square cells, row by row). The cell index travels in the instance
// color's alpha (alpha = (cell + 0.5) / CELL_CODE), so the renderer sets only
// a transform and a color per instance; the body is then drawn opaque.
// Looping painted projectiles (fire, ice, lightning, bomb fuse) also carry the next frame (blue) and the
// cross-fade weight (green): two samples are mixed, and the flame side of the picture ripples (see ripple).
// Vertex work and two texture samples: cheap for 1000+ projectiles.

// Grid of the atlas: columns and rows of square cells (ProjectileRenderer.BODY_COLUMNS, texture height / cell).
uniform float columns : hint_range(1.0, 32.0) = 16.0;
uniform float rows : hint_range(1.0, 32.0) = 6.0;
// Must match ProjectileRenderer.CELL_CODE.
const float CELL_CODE = 256.0;
// Cells that ripple: the energy loops (fireball, lightning, orb: ProjectileRenderer.ANIM); the bomb fuse before
// them and the grenade after them stay rigid.
const float RIPPLE_FIRST = 29.0;
const float RIPPLE_END = 65.0;
// Ripple: how far (share of the cell) the trail waves, and how fast.
const float RIPPLE = 0.035;
const float RIPPLE_SPEED = 13.0;

varying vec2 uv_a;
varying vec2 uv_b;
varying vec2 local;
varying float blend;
varying float band;
varying float ripple;

void vertex() {
	float cell = floor(COLOR.a * CELL_CODE);
	float next = floor(COLOR.b * CELL_CODE);
	local = UV;
	band = COLOR.r;
	blend = COLOR.g;
	ripple = step(RIPPLE_FIRST - 0.5, cell) * (1.0 - step(RIPPLE_END - 0.5, cell));
	// The quad covers only the used band of the cell (height = COLOR.r).
	// (A QuadMesh is drawn upside down in 2D: flip v so the art stands the way it was painted.)
	float v = 0.5 + (0.5 - UV.y) * COLOR.r;
	uv_a = vec2((UV.x + mod(cell, columns)) / columns, (v + floor(cell / columns)) / rows);
	uv_b = vec2((UV.x + mod(next, columns)) / columns, (v + floor(next / columns)) / rows);
	UV = uv_a;
	COLOR = vec4(1.0);
}

void fragment() {
	// The trail (left of the head) waves like a flame; the head stays put.
	float wave = sin(local.x * 11.0 - TIME * RIPPLE_SPEED + local.y * 5.0) * RIPPLE * ripple * (1.0 - local.x) * band;
	vec4 a = texture(TEXTURE, uv_a + vec2(0.0, wave));
	vec4 b = texture(TEXTURE, uv_b + vec2(0.0, wave));
	float alpha = mix(a.a, b.a, blend);
	vec3 rgb = (a.rgb * a.a * (1.0 - blend) + b.rgb * b.a * blend) / max(alpha, 0.001);
	COLOR = vec4(rgb, alpha);
}
