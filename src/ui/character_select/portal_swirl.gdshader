shader_type canvas_item;
// The seal gate picture with its portal turning like a black hole. Same picture, same
// portal: only the pixels inside the arch are rotated, more near the center. Two
// phases offset by half a period are cross-faded so the twist never winds up.
// `pull` (0..1) rises when the run starts: faster spin, darker core, drawn inward.

uniform vec2 center = vec2(0.507, 0.40);
// Half size of the arch's opening, in texture UV.
uniform vec2 radius = vec2(0.10, 0.205);
uniform float pull : hint_range(0.0, 1.0) = 0.0;
uniform float period = 5.0;

vec2 twirl(vec2 d, float r, float phase, float strength) {
	float inner = smoothstep(1.0, 0.0, r);
	float angle = phase * strength * (0.25 + 0.75 * inner * inner);
	float s = sin(angle);
	float c = cos(angle);
	return vec2(c * d.x - s * d.y, s * d.x + c * d.y);
}

void fragment() {
	vec2 d = (UV - center) / radius;
	float r = length(d);
	float mask = 1.0 - smoothstep(0.82, 1.0, r);
	float speed = 1.0 + 2.5 * pull;
	float cycle = TIME * speed / period;
	float p1 = fract(cycle);
	float p2 = fract(cycle + 0.5);
	float w1 = abs(2.0 * p1 - 1.0);
	float strength = 2.4 + 2.5 * pull;
	// Sampling further out than the pixel pulls the picture toward the center.
	float draw_in = 1.0 + 0.45 * pull * (1.0 - r);
	vec2 a = center + twirl(d, r, p1 * 2.0 - 1.0, strength) * draw_in * radius;
	vec2 b = center + twirl(d, r, p2 * 2.0 - 1.0, strength) * draw_in * radius;
	vec4 swirl = mix(texture(TEXTURE, a), texture(TEXTURE, b), w1);
	vec4 col = mix(texture(TEXTURE, UV), swirl, mask);
	// Dark heart and a soft violet glow at the rim, stronger when pulling.
	float heart = smoothstep(0.45, 0.0, r) * (0.3 + 0.6 * pull) * mask;
	col.rgb = mix(col.rgb, vec3(0.01, 0.0, 0.05), heart);
	float rim = smoothstep(0.5, 0.92, r) * (1.0 - smoothstep(0.92, 1.1, r));
	col.rgb += vec3(0.28, 0.16, 0.7) * rim * (0.10 + 0.08 * sin(TIME * 2.2)) * (1.0 + 2.0 * pull);
	COLOR = col;
}
