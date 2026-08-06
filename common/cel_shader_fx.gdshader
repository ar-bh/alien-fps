shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform int color_levels : hint_range(2, 16) = 4;
uniform float line_thickness : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec4 color = texture(screen_texture, SCREEN_UV);
    
    vec3 cel_color = floor(color.rgb * float(color_levels)) / float(color_levels);
    
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