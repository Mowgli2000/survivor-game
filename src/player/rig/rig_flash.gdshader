shader_type canvas_item;
// White hit flash of a CharacterRig (all its pieces share this material).
// COLOR already holds the texture color times the modulate.

uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash * 0.85);
}
