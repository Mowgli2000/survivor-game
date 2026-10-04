shader_type canvas_item;
// Player sprite (PlayerMotion): lower body sway (coat) while moving and the white
// hit flash. The sway shifts the texture lookup inside the frame, so the atlas
// padding must stay wider than the sway. Renderer: Compatibility; 1 texture read,
// drawn for 1-2 players only.

// Frame of the sprite in the atlas, in UV: top and height of a cell.
uniform float cell_v_top = 0.0;
uniform float cell_v_height = 1.0;
// Width of a cell, in UV.
uniform float cell_u_width = 1.0;
// 0..1: movement speed ratio.
uniform float sway : hint_range(0.0, 1.0) = 0.0;
// 0..1: white flash.
uniform float flash : hint_range(0.0, 1.0) = 0.0;

// Draw color alone (the fragment COLOR already includes the texture).
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	float t = clamp((UV.y - cell_v_top) / cell_v_height, 0.0, 1.0);
	// Only the lower part moves, more and more toward the hem.
	float weight = smoothstep(0.55, 1.0, t);
	vec2 uv = UV;
	// Wave travelling down the coat: 13 rad/s, ~1 wave per sprite height,
	// amplitude 2.2 % of the frame width at full speed.
	uv.x += sin(TIME * 13.0 + t * 7.0) * sway * weight * 0.022 * cell_u_width;
	vec4 c = texture(TEXTURE, uv) * tint;
	c.rgb = mix(c.rgb, vec3(1.0), flash * 0.85);
	COLOR = c;
}
