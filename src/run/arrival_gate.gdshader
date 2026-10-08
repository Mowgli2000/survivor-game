shader_type canvas_item;
// The gate the heroes walk out of at the start of a run: a procedural vortex inspired
// by two references (a blue whirlpool with a white-hot heart, a red one made of
// concentric ripples with dark debris and cracks of lightning). Spiral bands turning,
// ripple rings, a white core, wisps of lightning near the rim, dark flying shards, a
// glowing rim and a halo. One quad, no texture. Target: Compatibility renderer, one
// short fragment shader (a few noise lookups), a single instance on screen.

// 0 = closed, 1 = fully open (the portal grows from its center).
uniform float open : hint_range(0.0, 1.0) = 1.0;
// Palette: bright middle bands, outer body, deepest shade (blue by default; red for the
// last seal).
uniform vec3 mid : source_color = vec3(0.35, 0.9, 1.0);
uniform vec3 outer : source_color = vec3(0.22, 0.35, 1.0);
uniform vec3 deep : source_color = vec3(0.02, 0.03, 0.18);
// The sprite shows this many gate radii from the center to its edge.
const float VIEW_RADII = 1.7;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 * VIEW_RADII / max(open, 0.001);
	float r = length(p);
	float a = atan(p.y, p.x);
	float t = TIME;

	// Spiral bands: a logarithmic spiral, bent by turbulence that follows the flow.
	float n = noise(vec2(cos(a) * r * 2.0, sin(a) * r * 2.0 + t * 0.4) * 2.2);
	float band_a = 0.5 + 0.5 * sin(2.0 * a + 5.5 * log(r + 0.06) - t * 1.7 + n * 2.2);
	float band_b = 0.5 + 0.5 * sin(3.0 * a - 4.0 * log(r + 0.06) + t * 2.5 + n * 3.0);
	float ripple = 0.5 + 0.5 * sin(r * 30.0 - t * 5.5 + n * 2.0);

	float inside_mask = 1.0 - smoothstep(0.9, 1.0, r);
	vec3 col = mix(deep, outer, 0.3 + 0.7 * band_a);
	col = mix(col, mid, band_b * smoothstep(0.0, 0.85, 1.0 - r * 0.85) * 0.95);
	// Concentric ripples, stronger toward the rim.
	col += mid * ripple * 0.14 * smoothstep(0.25, 1.0, r);
	// White streaks where both bands peak, then the white-hot core.
	col += vec3(1.0) * pow(band_a * band_b, 2.0) * 0.55 * (1.0 - r * 0.7);
	float heart = exp(-r * r * 7.0);
	col = mix(col, vec3(1.0), clamp(heart * 1.5, 0.0, 1.0));

	// Wisps of lightning crawling near the rim.
	float bolt_noise = noise(vec2(a * 3.2 + t * 2.6, r * 7.0 - t * 1.3));
	float bolt = smoothstep(0.035, 0.0, abs(bolt_noise - 0.5)) * smoothstep(0.5, 0.92, r);
	col += mix(mid, vec3(1.0), 0.65) * bolt * 1.1 * inside_mask;

	// Dark shards drifting outward.
	vec2 q = p * 4.5 + vec2(0.0, t * 0.5);
	vec2 cell = floor(q);
	float shard = step(0.88, hash(cell)) * (1.0 - smoothstep(0.1, 0.24, length(fract(q) - 0.5)));
	col = mix(col, deep * 0.35, shard * smoothstep(0.3, 0.8, r) * inside_mask);

	// Bright rim.
	float rim = exp(-pow((r - 1.0) * 20.0, 2.0));
	col += mix(mid, vec3(1.0), 0.6) * rim * 1.6;

	// Halo outside the rim, fading to nothing before the sprite's edge.
	float halo = exp(-(r - 1.0) * 3.0) * (1.0 - smoothstep(1.3, VIEW_RADII, r)) * step(1.0, r);
	float inside = 1.0 - smoothstep(0.985, 1.02, r);
	float alpha = max(inside, halo * 0.6) * smoothstep(0.0, 0.05, open);
	vec3 out_col = r > 1.0 ? mix(outer, mid, 0.35) * halo : col;
	COLOR = vec4(max(out_col, vec3(0.0)), clamp(alpha, 0.0, 1.0));
}
