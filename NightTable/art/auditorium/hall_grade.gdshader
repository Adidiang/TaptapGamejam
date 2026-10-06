shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float softness : hint_range(0.0, 1.0) = 0.22;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.32;
uniform float grain_strength : hint_range(0.0, 0.05) = 0.006;
uniform float fringe : hint_range(0.0, 0.005) = 0.0006;
uniform float paper_strength : hint_range(0.0, 0.2) = 0.035;

float noise(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float paper_noise(vec2 p) {
	vec2 i=floor(p), f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(noise(i),noise(i+vec2(1,0)),f.x),mix(noise(i+vec2(0,1)),noise(i+vec2(1,1)),f.x),f.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - 0.5;
	vec2 fringe_offset = centered * fringe;
	vec3 sharp = textureLod(screen_texture, uv, 0.0).rgb;
	sharp.r = textureLod(screen_texture, uv + fringe_offset, 0.0).r;
	sharp.b = textureLod(screen_texture, uv - fringe_offset, 0.0).b;
	vec3 soft = textureLod(screen_texture, uv, 2.0).rgb;
	vec3 color = mix(sharp, soft, softness);
	vec3 glow = max(textureLod(screen_texture, uv, 3.5).rgb - vec3(0.52), vec3(0.0));
	vec3 halo = max(textureLod(screen_texture, uv, 5.0).rgb - vec3(0.55), vec3(0.0));
	color += glow * vec3(0.25, 0.24, 0.2) + halo * 0.35;
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	color = mix(vec3(luminance), color, 0.74);
	// Aged warm highlights, olive shadows, and a slightly lifted film black.
	float shadow = 1.0 - smoothstep(0.08, 0.65, luminance);
	color *= mix(vec3(1.025, 0.955, 1.0), vec3(0.9, 1.015, 1.025), shadow * 0.45);
	color = color * 0.86 + vec3(0.019, 0.028, 0.012);
	float edge = smoothstep(0.22, 0.69, length(centered * vec2(1.05, 1.0)));
	color *= 1.0 - edge * vignette_strength;
	color += (noise(FRAGCOORD.xy) - 0.5) * grain_strength;
	// Stationary irregular paper tooth and uneven pigment, with no blur.
	vec2 p=FRAGCOORD.xy;
	float tooth=paper_noise(p*0.65)-0.5;
	float fibre=paper_noise(p*vec2(0.12,0.8))-0.5;
	float wash=paper_noise(p*0.018)-0.5;
	color *= 1.0+paper_strength*(tooth*1.7+fibre+wash*0.7);
	color += (tooth+fibre)*paper_strength*0.18;
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}

