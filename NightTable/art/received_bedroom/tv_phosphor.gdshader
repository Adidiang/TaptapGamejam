shader_type spatial;
render_mode cull_back;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform float phosphor_energy : hint_range(0.0, 5.0) = 2.4;
void fragment() {
	vec3 color = texture(albedo_map, UV).rgb;
	ALBEDO = color;
	ROUGHNESS = 0.75;
	// The CRT test-pattern is much cooler/brighter than its wooden casing.
	float mask = smoothstep(0.19, 0.52, max(color.b, color.g * 0.85));
	EMISSION = color * mask * phosphor_energy * vec3(0.8, 1.0, 0.92);
}
