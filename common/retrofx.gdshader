shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

void fragment() {
	vec2 grid = vec2(textureSize(SCREEN_TEXTURE, 0)) / pixel_size;
	vec2 uv = floor(SCREEN_UV * grid) / grid;
	COLOR = texture(SCREEN_TEXTURE, uv);
}