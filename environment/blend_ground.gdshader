shader_type spatial;

uniform sampler2D tex_a : source_color;
uniform sampler2D tex_b : source_color;
uniform vec3 uv_scale_a = vec3(2.0, 2.0, 1.0);
uniform vec3 uv_scale_b = vec3(2.0, 2.0, 1.0);
uniform float chunk_width = 50.0;

varying float mask;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	mask = clamp((VERTEX.x / chunk_width) + 0.5, 0.0, 1.0);
}

void fragment() {
	vec2 uv_a = (world_pos.xz / chunk_width) * uv_scale_a.xy;
	vec2 uv_b = (world_pos.xz / chunk_width) * uv_scale_b.xy;
	ALBEDO = mix(texture(tex_a, uv_a).rgb, texture(tex_b, uv_b).rgb, mask);
}