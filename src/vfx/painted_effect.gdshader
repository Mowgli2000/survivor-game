shader_type canvas_item;
render_mode blend_premul_alpha;
// Painted combat effects (Vfx SHEET layer). Premultiplied alpha like a normal painting, plus a
// "keep the hero visible" fade: inside a small circle around each guarded hero (screen pixels,
// set by Vfx every frame) the effect drops to `floor_alpha`, so a swing never hides the player.

uniform vec2 guard_a = vec2(-10000.0);
uniform vec2 guard_b = vec2(-10000.0);
uniform float guard_radius = 60.0;
uniform float floor_alpha : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	float d = min(distance(FRAGCOORD.xy, guard_a), distance(FRAGCOORD.xy, guard_b));
	float k = mix(floor_alpha, 1.0, smoothstep(guard_radius * 0.55, guard_radius, d));
	COLOR *= texture(TEXTURE, UV) * k;
}
