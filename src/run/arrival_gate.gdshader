shader_type canvas_item;
// The gate the heroes drop out of at the start of a run: a procedural vortex.
// Spiral arms of two colors turning at different speeds with turbulence, a black
// core ringed by a hot accretion circle, a bright rim, a rune ring turning the other
// way and a soft halo. One quad, no textures. Target: Compatibility renderer, one
// short fragment shader (a few noise lookups), a single instance on screen.

uniform float open : hint_range(0.0, 1.0) = 1.0;
uniform vec3 violet : source_color = vec3(0.55, 0.22, 1.0);
uniform vec3 blue : source_color = vec3(0.25, 0.65, 1.0);
uniform vec3 deep : source_color = vec3(0.03, 0.0, 0.10);
// The sprite shows this many gate radii from the center to its edge.
const float VIEW_RADII = 1.6;
const float ARMS = 5.0;

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

	// Turbulence follows the spiral so the arms look like flowing matter.
	float n = noise(vec2(a * 1.5 + t * 0.25, r * 3.5 - t * 0.9));
	float spin1 = sin(ARMS * a + 7.0 * sqrt(r) - t * 2.2 + n * 2.4);
	float spin2 = sin((ARMS + 2.0) * a - 11.0 * sqrt(r) + t * 3.1 + n * 3.0);
	float arm1 = smoothstep(0.15, 0.95, 0.5 + 0.5 * spin1);
	float arm2 = smoothstep(0.35, 1.0, 0.5 + 0.5 * spin2);

	float body = smoothstep(0.06, 0.4, r) * (1.0 - smoothstep(0.88, 1.0, r));
	vec3 col = deep;
	col = mix(col, violet, arm1 * body);
	col = mix(col, blue, arm2 * body * 0.85);
	col += vec3(1.0, 0.9, 1.0) * pow(arm1 * arm2, 2.0) * body * 0.6;

	// Black core and its hot ring.
	col *= smoothstep(0.05, 0.3, r);
	float ring_hot = exp(-pow((r - 0.3) * 16.0, 2.0));
	col += mix(violet, vec3(1.0), 0.6) * ring_hot * (0.7 + 0.3 * sin(t * 5.0));

	// Bright rim and the rune ring turning the other way.
	float rim = exp(-pow((r - 1.0) * 22.0, 2.0));
	col += mix(violet, vec3(1.0), 0.5) * rim * 1.4;
	float runes_zone = smoothstep(1.08, 1.11, r) * (1.0 - smoothstep(1.15, 1.18, r));
	float seg = a * 28.0 / 6.2831853 - t * 0.2;
	float runes = smoothstep(0.3, 0.4, fract(seg)) * (1.0 - smoothstep(0.6, 0.7, fract(seg))) * step(0.4, hash(vec2(floor(seg), 3.0)));

	// Halo outside the rim, fading to nothing before the sprite's edge.
	float halo = exp(-(r - 1.0) * 3.2) * (1.0 - smoothstep(1.35, VIEW_RADII, r)) * step(1.0, r);
	float inside = 1.0 - smoothstep(0.985, 1.02, r);
	float alpha = max(inside, halo * 0.55 + runes_zone * runes * 0.7);
	alpha *= smoothstep(0.0, 0.05, open);
	vec3 out_col = r > 1.0 ? mix(violet, blue, 0.3) * halo * 0.9 + blue * runes_zone * runes * 0.8 : col;
	COLOR = vec4(max(out_col, vec3(0.0)), clamp(alpha, 0.0, 1.0));
}
