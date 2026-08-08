shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform int color_levels : hint_range(2, 16) = 8;
uniform float line_thickness : hint_range(0.0, 5.0) = 1.0;
uniform float brightness : hint_range(0.5, 2.0) = 1.15;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);

	float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	float levels = float(color_levels);
	float q = floor(luma * levels * brightness + 0.5) / levels;
	q = clamp(q, 0.0, 1.0);
	vec3 cel_color = color.rgb / max(luma, 1e-5) * q;

	vec2 size = SCREEN_PIXEL_SIZE * line_thickness;
	vec3 c1 = texture(screen_texture, SCREEN_UV + vec2(-size.x, 0.0)).rgb;
	vec3 c2 = texture(screen_texture, SCREEN_UV + vec2(size.x, 0.0)).rgb;
	vec3 c3 = texture(screen_texture, SCREEN_UV + vec2(0.0, -size.y)).rgb;
	vec3 c4 = texture(screen_texture, SCREEN_UV + vec2(0.0, size.y)).rgb;

	float edge = length(c1 - c2) + length(c3 - c4);

	if (edge > 0.2) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		COLOR = vec4(cel_color, color.a);
	}
}