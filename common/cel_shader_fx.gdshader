shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform int color_levels : hint_range(2, 16) = 8;
uniform float line_thickness : hint_range(0.0, 6.0) = 0.5;
uniform float edge_threshold : hint_range(0.01, 1.0) = 0.15;
uniform float brightness : hint_range(0.5, 2.0) = 1.15;

float edge_at(vec2 uv, vec2 pixel) {
	vec3 c1 = texture(screen_texture, uv + vec2(-pixel.x, 0.0)).rgb;
	vec3 c2 = texture(screen_texture, uv + vec2(pixel.x, 0.0)).rgb;
	vec3 c3 = texture(screen_texture, uv + vec2(0.0, -pixel.y)).rgb;
	vec3 c4 = texture(screen_texture, uv + vec2(0.0, pixel.y)).rgb;
	return length(c1 - c2) + length(c3 - c4);
}

void fragment() {
	vec2 pixel = 1.0 / vec2(textureSize(screen_texture, 0));
	vec4 color = texture(screen_texture, SCREEN_UV);

	float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	float levels = float(color_levels);
	float q = floor(luma * levels * brightness + 0.5) / levels;
	q = clamp(q, 0.0, 1.0);
	vec3 cel_color = color.rgb / max(luma, 1e-5) * q;

	bool outline = false;
	int radius = int(ceil(line_thickness));
	for (int x = -6; x <= 6; x++) {
		for (int y = -6; y <= 6; y++) {
			if (abs(x) > radius || abs(y) > radius) {
				continue;
			}
			vec2 uv = SCREEN_UV + vec2(float(x), float(y)) * pixel;
			if (edge_at(uv, pixel) > edge_threshold) {
				outline = true;
			}
		}
	}

	if (outline) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		COLOR = vec4(cel_color, color.a);
	}
}