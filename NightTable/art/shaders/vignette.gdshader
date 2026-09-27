// 简单暗角 shader（替代 Godot 4 缺失的 Environment.vignette_intensity）
// 用法：ColorRect 全屏覆盖在最顶层 CanvasLayer，material 指 ShaderMaterial
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 2.0) = 0.4;    // 暗角强度（0=不暗）
uniform float radius : hint_range(0.0, 1.0) = 0.45;      // 暗角起点（中心到边角比例）
uniform float softness : hint_range(0.0, 1.0) = 0.5;   // 边缘渐变软度
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	float dist = distance(uv, vec2(0.5));
	float t = smoothstep(radius, radius + softness, dist);
	COLOR = vec4(vignette_color.rgb, t * intensity);
}