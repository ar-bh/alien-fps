shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float line_thickness : hint_range(0.5, 4.0) = 1.5;
uniform float alpha_threshold : hint_range(0.01, 0.5) = 0.1;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	vec2 pixel = line_thickness / vec2(textureSize(screen_texture, 0));

	float a = color.a;
	float a_l = texture(screen_texture, SCREEN_UV + vec2(-pixel.x, 0.0)).a;
	float a_r = texture(screen_texture, SCREEN_UV + vec2(pixel.x, 0.0)).a;
	float a_u = texture(screen_texture, SCREEN_UV + vec2(0.0, -pixel.y)).a;
	float a_d = texture(screen_texture, SCREEN_UV + vec2(0.0, pixel.y)).a;

	float edge = abs(a - a_l) + abs(a - a_r) + abs(a - a_u) + abs(a - a_d);

	if (edge > alpha_threshold && a > alpha_threshold) {

		COLOR = outline_color;
	} else {
		COLOR = color;
	}
}