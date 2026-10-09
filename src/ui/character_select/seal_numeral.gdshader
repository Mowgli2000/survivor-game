shader_type canvas_item;
// Recolors the numeral painted on a medallion of seal_gate_v3.png: the light pixels of the
// painted numeral (the medallion's inner area only, not its metal rim) are redrawn in the seal's
// color, so the numeral itself takes the portal's color, with no extra shape over the picture.
// `tint_strength` 0..1 fades the effect; `dark` darkens a locked seal's numeral instead.
// Author: Claude Code, session 11 (theme T3).

uniform vec3 tint : source_color = vec3(1.0, 0.3, 0.3);
uniform float tint_strength : hint_range(0.0, 1.0) = 1.0;
// The medallion's cell in the picture's UV (x, y, width, height): UV is the picture's here.
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform float dark : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float lum = dot(c, vec3(0.3, 0.59, 0.11));
	// The numeral is the light part of the medallion's inner disc.
	float mask = smoothstep(0.2, 0.3, lum);
	// Only the inner disc of the medallion: never its metal rim, its spikes or the light around it.
	float disc = 1.0 - smoothstep(0.46, 0.54, length(((UV - region.xy) / region.zw - 0.5) * 2.0 * vec2(0.8, 1.15)));
	mask *= disc;
	vec3 lit = mix(tint * (0.7 + 0.8 * lum), tint * 0.15, dark);
	COLOR = vec4(lit, mask * tint_strength);
}
