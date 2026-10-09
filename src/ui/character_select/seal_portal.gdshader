shader_type canvas_item;
// Seal screen portal: the painted portal of the gate picture (seal_gate_v3.png, the dev's own
// picture) comes alive and takes the color of the pointed seal. The shader re-draws the picture
// inside the stone arch with a slow twirl (two phases cross-faded so the twist never winds up:
// the spiral, its blades of light and its floating rocks turn like a whirlpool), then recolors
// it with a gradient map on its tones (flat 2D shapes stay flat). Light spills on the stones
// around the opening in the seal's color.
// Target: Compatibility renderer, one quad, 3 texture taps per pixel, one instance on screen.
// Author: Claude Code, session 11 (theme T3).

// The quad covers this part of the picture (share of width, of height).
uniform vec2 rect_min = vec2(0.22, 0.08);
uniform vec2 rect_size = vec2(0.56, 0.66);
// The arch opening, in picture shares: center x, top (apex), where the straight sides start,
// bottom (the stairs), half width.
uniform float arch_center_x = 0.5015;
uniform float arch_top = 0.2;
uniform float arch_spring = 0.34;
uniform float arch_bottom = 0.625;
uniform float arch_half_width = 0.0945;
// The swirl's heart in the picture and the size of its ellipse (share of the picture).
uniform vec2 heart = vec2(0.5015, 0.415);
// The part of the picture the swirl is read from: kept well inside the arch so no stone, no
// stairs and no arch edge is ever dragged into the portal (dev's remark).
uniform vec2 swirl_radius = vec2(0.07, 0.15);
// The picture itself (set by SealSelect).
uniform sampler2D vortex : source_color, filter_linear;
// Palette: bright, body, shade (SealSelect derives them from the seal color).
uniform vec3 mid : source_color = vec3(0.35, 0.9, 1.0);
uniform vec3 outer : source_color = vec3(0.22, 0.35, 1.0);
uniform vec3 deep : source_color = vec3(0.02, 0.03, 0.18);
// 0..1, rises while the run starts: faster twirl.
uniform float pull : hint_range(0.0, 1.0) = 0.0;
// Strength of the light spilling on the stones outside the opening.
uniform float spill : hint_range(0.0, 1.0) = 0.35;
uniform float twirl_strength = 2.4;
uniform float period = 6.0;

// The picture is 1536 x 1024: a share of its height is this many shares of its width.
const float HEIGHT_TO_WIDTH = 0.6667;

// The six medallions of the arch (SealSelect.MEDALLIONS) and the radius, in shares of the picture's
// width, of the metal ring with its spikes: the light spilling on the stones never reaches them
// (a bit of the portal color showed on the ring of the I, dev 2026-10-09).
const vec2 MEDALLIONS[6] = vec2[6](vec2(0.369, 0.405), vec2(0.382, 0.288), vec2(0.430, 0.180),
		vec2(0.570, 0.180), vec2(0.617, 0.285), vec2(0.630, 0.408));
const float MEDALLION_CLEAR = 0.04;

// 0 on a medallion, 1 away from them.
float medallion_free(vec2 q) {
	float free_of = 1.0;
	for (int i = 0; i < 6; i++) {
		vec2 delta = (q - MEDALLIONS[i]) * vec2(1.0, HEIGHT_TO_WIDTH);
		free_of = min(free_of, smoothstep(MEDALLION_CLEAR - 0.006, MEDALLION_CLEAR, length(delta)));
	}
	return free_of;
}

// Signed depth inside the arch (positive inside), in shares of the picture's width.
float arch_depth(vec2 q) {
	float dx = q.x - arch_center_x;
	float side = arch_half_width - abs(dx);
	if (q.y >= arch_spring) {
		return min(side, (arch_bottom - q.y) * HEIGHT_TO_WIDTH);
	}
	vec2 e = vec2(dx / arch_half_width, (q.y - arch_spring) / (arch_spring - arch_top));
	return (1.0 - length(e)) * arch_half_width;
}

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
	vec2 q = rect_min + UV * rect_size;
	float depth = arch_depth(q);
	float inside = smoothstep(-0.002, 0.006, depth);
	// Output position in the opening's own units (1 = the arch's edge), compressed so that the whole
	// opening, corners included, reads from the safe middle of the painted portal.
	vec2 d_out = (q - heart) / vec2(0.1, 0.215);
	float r_out = length(d_out);
	float r = clamp(tanh(r_out * 0.95) * 1.05, 0.0, 0.98);
	vec2 d = d_out / max(r_out, 0.0001) * r;
	float speed = 1.0 + 2.0 * pull;
	float cycle = TIME * speed / period;
	float p1 = fract(cycle);
	float p2 = fract(cycle + 0.5);
	float w1 = abs(2.0 * p1 - 1.0);
	vec3 a = texture(vortex, heart + twirl(d, r, p1 * 2.0 - 1.0, twirl_strength) * swirl_radius).rgb;
	vec3 b = texture(vortex, heart + twirl(d, r, p2 * 2.0 - 1.0, twirl_strength) * swirl_radius).rgb;
	vec3 painted = mix(a, b, w1);
	float g = dot(painted, vec3(0.3, 0.59, 0.11)) * 1.25;
	vec3 col = gradient_map(g);
	// A lit lip along the stone edge, a soft pulse.
	col += mix(mid, vec3(1.0), 0.4) * exp(-max(depth, 0.0) * 120.0) * 0.35;
	col *= 0.94 + 0.06 * sin(TIME * 1.6 + r * 2.0);

	// Light spilling on the stones outside the opening.
	float outside = max(-depth, 0.0);
	float glow = exp(-outside * 34.0) * (1.0 - inside) * spill * (0.85 + 0.15 * sin(TIME * 2.0));
	float below = 1.0 - smoothstep(arch_bottom, arch_bottom + 0.02, q.y);
	vec3 spill_col = mix(mid, outer, 0.4);
	float alpha = max(inside, clamp(glow * 0.55 * medallion_free(q), 0.0, 0.7)) * below;
	COLOR = vec4(mix(spill_col, col, inside), clamp(alpha, 0.0, 1.0));
}
