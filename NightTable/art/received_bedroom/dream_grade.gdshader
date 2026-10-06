shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float softness : hint_range(0.0, 1.0) = 0.22;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.32;
uniform float grain_strength : hint_range(0.0, 0.05) = 0.006;
uniform float fringe : hint_range(0.0, 0.005) = 0.0006;
uniform float paper_strength : hint_range(0.0, 0.2) = 0.035;
// Optical diffusion: illuminate around bright sources without lifting every black.
uniform float diffusion_strength : hint_range(0.0, 2.0) = 0.85;
uniform float highlight_threshold : hint_range(0.1, 0.95) = 0.58;
uniform float diffusion_radius : hint_range(0.25, 3.0) = 1.0;
uniform float shadow_depth : hint_range(1.0, 1.6) = 1.20;
uniform float color_retention : hint_range(0.0, 1.2) = 0.94;
uniform float dream_haze : hint_range(0.0, 1.0) = 0.55;
uniform float mist_density : hint_range(0.0, 0.6) = 0.28;

float noise(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float paper_noise(vec2 p) {
	vec2 i=floor(p), f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(noise(i),noise(i+vec2(1,0)),f.x),mix(noise(i+vec2(0,1)),noise(i+vec2(1,1)),f.x),f.y);
}

vec3 bright_sample(vec2 uv, float lod) {
	vec3 c = textureLod(screen_texture, uv, lod).rgb;
	float peak = max(c.r, max(c.g, c.b));
	return c * smoothstep(highlight_threshold, 1.0, peak);
}

vec3 diffusion(vec2 uv, float radius, float lod) {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 d = vec2(screen_size.y / screen_size.x, 1.0) * radius * diffusion_radius;
	vec3 sum = bright_sample(uv, lod) * 2.0;
	sum += bright_sample(uv + vec2(d.x, 0.0), lod);
	sum += bright_sample(uv - vec2(d.x, 0.0), lod);
	sum += bright_sample(uv + vec2(0.0, d.y), lod);
	sum += bright_sample(uv - vec2(0.0, d.y), lod);
	sum += bright_sample(uv + d * 0.707, lod);
	sum += bright_sample(uv - d * 0.707, lod);
	sum += bright_sample(uv + vec2(d.x, -d.y) * 0.707, lod);
	sum += bright_sample(uv + vec2(-d.x, d.y) * 0.707, lod);
	return sum / 10.0;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - 0.5;
	vec2 fringe_offset = centered * fringe;
	vec3 sharp = textureLod(screen_texture, uv, 0.0).rgb;
	sharp.r = textureLod(screen_texture, uv + fringe_offset, 0.0).r;
	sharp.b = textureLod(screen_texture, uv - fringe_offset, 0.0).b;
	vec3 soft = textureLod(screen_texture, uv, 2.0).rgb;
	float highlight = smoothstep(0.4, 0.9, max(sharp.r, max(sharp.g, sharp.b)));
	vec3 color = mix(sharp, soft, softness * highlight);
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	color = mix(vec3(luminance), color, color_retention);
	color = pow(max(color, vec3(0.0)), vec3(shadow_depth));
	// A restrained lavender bias in reflected light; no olive wash or black offset.
	vec3 bloom = diffusion(uv, 0.004, 1.5) * 0.65 + diffusion(uv, 0.017, 3.0) * 0.35;
	bloom *= vec3(1.025, 0.98, 1.035) * diffusion_strength;
	// Keep the source's engraved/painted detail while its surroundings catch the halo.
	bloom *= 1.0 - 0.65 * smoothstep(0.55, 0.95, luminance);
	// Wide, source-colored optical haze. Protect deep shadows and bright cores
	// instead of adding a constant gray veil over the whole screen.
	vec3 haze = diffusion(uv, 0.045, 4.5);
	float shadow_protection = mix(0.15, 1.0, smoothstep(0.025, 0.22, luminance));
	float core_protection = 1.0 - 0.8 * smoothstep(0.55, 0.95, luminance);
	bloom += haze * dream_haze * shadow_protection * core_protection;
	// Screen blend retains highlight detail instead of clipping additive glow.
	color = 1.0 - (1.0 - clamp(color, vec3(0.0), vec3(1.0))) * exp(-bloom);
	// Broad colored veil also reaches midtones, like the soft faded reference.
	// Local color keeps pink walls and green furniture distinct; no white fog fill.
	vec3 local_wash = textureLod(screen_texture, uv, 5.5).rgb;
	vec3 mist_color = mix(vec3(0.34, 0.325, 0.285), local_wash, 0.5);
	float mist_mask = 1.0 - 0.72 * smoothstep(0.45, 0.95, luminance);
	color = mix(color, mist_color, mist_density * mist_mask);
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
