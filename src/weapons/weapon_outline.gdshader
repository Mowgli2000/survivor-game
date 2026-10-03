shader_type canvas_item;
// Draws the texture untinted with an outline in the draw color (rarity tier).
// Used by WeaponVisuals: draw_texture(icon, pos, Tiers.color(level)).

uniform float width = 7.0; // in texture pixels

varying vec4 outline_color;

void vertex() {
	outline_color = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 d = TEXTURE_PIXEL_SIZE * width;
	float a = 0.0;
	a = max(a, texture(TEXTURE, UV + vec2(d.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV - vec2(d.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV + vec2(0.0, d.y)).a);
	a = max(a, texture(TEXTURE, UV - vec2(0.0, d.y)).a);
	a = max(a, texture(TEXTURE, UV + d * 0.7).a);
	a = max(a, texture(TEXTURE, UV - d * 0.7).a);
	a = max(a, texture(TEXTURE, UV + vec2(d.x, -d.y) * 0.7).a);
	a = max(a, texture(TEXTURE, UV + vec2(-d.x, d.y) * 0.7).a);
	float outline = a * (1.0 - tex.a);
	// Draw alpha (tier color x inherited modulate, e.g. the player's hit blink) fades both.
	COLOR = vec4(mix(outline_color.rgb, tex.rgb, tex.a), max(tex.a, outline) * outline_color.a);
}
