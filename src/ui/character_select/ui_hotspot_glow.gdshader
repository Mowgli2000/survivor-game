shader_type canvas_item;
render_mode blend_add;
// Hover effects of UiHotspots drawn from a region of the painted background itself, so the
// crystal or the seal's lines ARE the painting shining more, not an overlay shape:
// mode 0 = crystal (the painted crystal gets bluer and brighter, with a soft bloom around it),
// mode 1 = seal (its painted lines blink slowly: bright, normal, bright, evenly over the whole
// seal). The window of the region is a soft ellipse, so no rectangle ever shows.
// The caller's modulate carries r = random phase 0..1, a = hover level 0..1.
// Target: Compatibility renderer, a few quads only while hovered, up to 25 taps (crystal bloom).
// Author: Claude Code, session 11 (theme T3).

uniform int mode = 0;
// How much brighter the painting gets at full level.
uniform float gain = 1.4;
// Texel size of the region for the bloom taps, in UV of the region.
uniform vec2 bloom_step = vec2(0.01, 0.01);
// Tint pushed into the glow.
uniform vec3 tint : source_color = vec3(0.3, 0.7, 1.0);
// What counts as "light" in the painting: rises between these two values.
uniform float light_low = 0.4;
uniform float light_high = 0.7;

// The caller's modulate, kept before the engine multiplies COLOR by the texture.
varying vec4 modulate_in;

void vertex() {
	modulate_in = COLOR;
}

float lightness(vec3 c) {
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	return smoothstep(light_low, light_high, max(l * 1.4, max(c.b, c.r) * 0.9 - 0.05));
}

void fragment() {
	float level = modulate_in.a;
	float phase = modulate_in.r * 6.2832;
	// Soft elliptical window (1 at the middle, 0 at the edge of the region).
	vec2 e = (UV - 0.5) * 2.0;
	float window = 1.0 - smoothstep(0.35, 0.8, length(e));
	vec3 c = texture(TEXTURE, UV).rgb;
	float m = lightness(c);
	if (mode == 0) {
		// Bloom: the light of the neighbours spreads (24 taps).
		float bloom = 0.0;
		for (int i = -2; i <= 2; i++) {
			for (int j = -2; j <= 2; j++) {
				if (i == 0 && j == 0) {
					continue;
				}
				vec3 n = texture(TEXTURE, UV + vec2(float(i), float(j)) * bloom_step * 1.6).rgb;
				bloom += lightness(n) / (1.0 + float(abs(i) + abs(j)));
			}
		}
		bloom *= 0.14;
		float pulse = 0.88 + 0.12 * sin(TIME * 2.6 + phase);
		// Only the crystal's own pixels shine (m masks them); the bloom is kept inside them.
		vec3 lit = c * m * gain + tint * m * (0.3 + bloom * 0.8);
		COLOR = vec4(lit * window * level * pulse, 1.0);
	} else {
		// The seal: its painted lines brighten the same everywhere (no hot center), blinking slowly.
		float blink = 0.5 - 0.5 * cos(TIME * 2.4);
		float strength = level * mix(0.25, 1.0, blink);
		vec3 lit = min(c * m * gain, vec3(0.55)) + tint * m * 0.22;
		COLOR = vec4(lit * window * strength, 1.0);
	}
}
