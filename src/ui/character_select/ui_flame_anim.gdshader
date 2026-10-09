shader_type canvas_item;
render_mode blend_add;
// Hover flame of the painted braziers: the 8 frames of a looping flame animation (AI-drawn in the
// style of the pictures' own flames, flame_sheet.png, a 4 x 2 grid on black) played in a loop and
// softly cross-faded, added over the painted flame. The base of every frame sits at the bottom of
// its cell. `level` fades it in and out (hover), `violet` recolors blue -> violet.
// Target: Compatibility renderer, 2 texture taps, a dozen small quads only while hovered.
// Author: Claude Code, session 11 (theme T3).

uniform sampler2D sheet : source_color, filter_linear;
uniform float level : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
uniform float violet : hint_range(0.0, 1.0) = 0.0;
// Frames per second of the loop.
uniform float fps = 11.0;

const vec2 GRID = vec2(4.0, 2.0);

vec3 frame_color(float index, vec2 uv) {
	float i = mod(index, 8.0);
	vec2 cell = vec2(mod(i, 4.0), floor(i / 4.0));
	return texture(sheet, (cell + uv) / GRID).rgb;
}

void fragment() {
	float t = TIME * fps + seed * 8.0;
	float i = floor(t);
	float mixer = smoothstep(0.0, 1.0, fract(t));
	// A little life on top of the frames: the whole flame leans with a slow breath.
	vec2 uv = UV;
	uv.x += sin(TIME * 3.0 + seed * 7.0 + (1.0 - UV.y) * 4.0) * 0.012 * (1.0 - UV.y);
	vec3 col = mix(frame_color(i, uv), frame_color(i + 1.0, uv), mixer);
	// Violet: blue -> purple.
	col = mix(col, vec3(col.b * 0.55 + col.r * 0.4, col.g * 0.28, col.b), violet);
	// Fade the cell's own edges so no rectangle shows.
	float edge = smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x) * smoothstep(1.0, 0.94, UV.y) * smoothstep(0.0, 0.04, UV.y);
	COLOR = vec4(col * edge * level * 1.05, 1.0);
}
