shader_type canvas_item;
// Colorblind correction (daltonization) of the whole screen: the colors the player cannot tell apart are
// moved onto the channels they can see. mode: 1 protanopia, 2 deuteranopia, 3 tritanopia.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform int mode = 1;

// Machado et al. (2009) simulation matrices, severity 1.0, one row per output channel.
vec3 simulate(vec3 c) {
	if (mode == 1) {
		return vec3(dot(vec3(0.152286, 1.052583, -0.204868), c), dot(vec3(0.114503, 0.786281, 0.099216), c),
			dot(vec3(-0.003882, -0.048116, 1.051998), c));
	}
	if (mode == 2) {
		return vec3(dot(vec3(0.367322, 0.860646, -0.227968), c), dot(vec3(0.280085, 0.672501, 0.047413), c),
			dot(vec3(-0.011820, 0.042940, 0.968881), c));
	}
	return vec3(dot(vec3(1.255528, -0.076749, -0.178779), c), dot(vec3(-0.078411, 0.930809, 0.147602), c),
		dot(vec3(0.004733, 0.691367, 0.303900), c));
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec3 error = c - simulate(c);
	vec3 shifted;
	if (mode == 3) {
		shifted = vec3(error.r + 0.7 * error.b, error.g + 0.7 * error.b, 0.0);
	} else {
		shifted = vec3(0.0, 0.7 * error.r + error.g, 0.7 * error.r + error.b);
	}
	COLOR = vec4(clamp(c + shifted, 0.0, 1.0), 1.0);
}
