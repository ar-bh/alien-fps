shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float line_thickness : hint_range(1.0, 12.0) = 3.0;
uniform float edge_threshold : hint_range(0.001, 1.0) = 0.1;
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	vec2 pixel = 1.0 / vec2(textureSize(screen_texture, 0));
	int radius = int(max(ceil(line_thickness), 1.0));

	float max_l = 0.0;
	float min_l = 1.0;

	for (int x = -12; x <= 12; x++) {
		for (int y = -12; y <= 12; y++) {
			if (abs(x) > radius || abs(y) > radius) {
				continue;
			}
			float l = lum(texture(screen_texture, SCREEN_UV + vec2(float(x), float(y)) * pixel).rgb);
			max_l = max(max_l, l);
			min_l = min(min_l, l);
		}
	}

	bool edge = (max_l - min_l) > edge_threshold;
	if (edge) {
		COLOR = outline_color;
	} else {
		COLOR = color;
	}
}