shader_type canvas_item;
// The gate the heroes walk out of at the start of a run. It is the SAME portal as the one of the
// seal screen (seal_portal.gdshader): the painted portal of the gate picture (seal_gate_v3.png),
// read from its safe middle, slowly twirled and recolored with the chosen seal's palette; the
// gate here is an ellipse (seen three-quarter face) with a bright rim and a halo, and it opens from
// its center. Target: Compatibility renderer, one quad, 3 texture taps, a single instance on screen.
// Author: Claude Code, session 11 (theme T3).

// 0 = closed, 1 = fully open (the portal grows from its center).
uniform float open : hint_range(0.0, 1.0) = 1.0;
// Palette: bright, body, shade (ArrivalGate.palette_for(seal color), same as the seal screen).
uniform vec3 mid : source_color = vec3(0.35, 0.9, 1.0);
uniform vec3 outer : source_color = vec3(0.22, 0.35, 1.0);
uniform vec3 deep : source_color = vec3(0.02, 0.03, 0.18);
// The painted picture and where its swirl is (see seal_portal.gdshader).
uniform sampler2D vortex : source_color, filter_linear;
uniform vec2 heart = vec2(0.5015, 0.415);
uniform vec2 swirl_radius = vec2(0.07, 0.15);
uniform float twirl_strength = 2.4;
uniform float period = 6.0;
// The sprite shows this many gate radii from the center to its edge.
const float VIEW_RADII = 1.7;

// Palette gradient map: dark -> deep -> body -> bright -> white.
vec3 gradient_map(float g) {
	vec3 c = mix(deep * 0.25, deep, smoothstep(0.02, 0.18, g));
	c = mix(c, outer, smoothstep(0.15, 0.42, g));
	c = mix(c, mid, smoothstep(0.4, 0.7, g));
	c = mix(c, vec3(1.0), smoothstep(0.72, 1.0, g) * 0.6);
	return c;
}

vec2 twirl(vec2 d, float r, float phase, float strength) {
	float inner = smoothstep(1.0, 0.0, r);
	float angle = phase * strength * (0.25 + 0.75 * inner * inner);
	float s = sin(angle);
	float c = cos(angle);
	return vec2(c * d.x - s * d.y, s * d.x + c * d.y);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 * VIEW_RADII / max(open, 0.001);
	float r_out = length(p);
	float inside = 1.0 - smoothstep(0.985, 1.02, r_out);
	// Same reading as the seal screen: the gate's whole disc reads from the safe middle of the picture.
	float r = clamp(tanh(r_out * 0.95) * 1.05, 0.0, 0.98);
	vec2 d = p / max(r_out, 0.0001) * r;
	float cycle = TIME / period;
	float p1 = fract(cycle);
	float p2 = fract(cycle + 0.5);
	float w1 = abs(2.0 * p1 - 1.0);
	vec3 a = texture(vortex, heart + twirl(d, r, p1 * 2.0 - 1.0, twirl_strength) * swirl_radius).rgb;
	vec3 b = texture(vortex, heart + twirl(d, r, p2 * 2.0 - 1.0, twirl_strength) * swirl_radius).rgb;
	float g = dot(mix(a, b, w1), vec3(0.3, 0.59, 0.11)) * 1.25;
	vec3 col = gradient_map(g);

	// Bright rim of the gate, a soft pulse inside.
	float rim = exp(-pow((r_out - 1.0) * 18.0, 2.0));
	col += mix(mid, vec3(1.0), 0.5) * rim * 1.1;
	col *= 0.94 + 0.06 * sin(TIME * 1.6 + r_out * 2.0);

	// Halo outside the rim, fading to nothing before the sprite's edge.
	float halo = exp(-(r_out - 1.0) * 3.0) * (1.0 - smoothstep(1.3, VIEW_RADII, r_out)) * step(1.0, r_out);
	float alpha = max(inside, halo * 0.6) * smoothstep(0.0, 0.05, open);
	vec3 out_col = r_out > 1.0 ? mix(outer, mid, 0.35) * halo : col;
	COLOR = vec4(max(out_col, vec3(0.0)), clamp(alpha, 0.0, 1.0));
}
