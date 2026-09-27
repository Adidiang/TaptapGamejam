shader_type spatial;
render_mode specular_disabled;

uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec4 base_color : source_color = vec4(1.0);
uniform float texture_softness : hint_range(0.0, 6.0) = 3.2;
uniform float color_steps : hint_range(3.0, 24.0) = 9.0;
uniform float saturation : hint_range(0.0, 1.5) = 0.8;
uniform float storybook_strength = 0.0;
uniform bool cutout = false;
uniform float cutoff = 0.33;
uniform vec3 shadow_tint : source_color = vec3(0.27, 0.37, 0.43);
varying vec3 pigment_position;

float pigment_hash(vec3 p) {
	return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);
}
float brush_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(mix(pigment_hash(cell),pigment_hash(cell+vec3(1,0,0)),f.x),
		mix(pigment_hash(cell+vec3(0,1,0)),pigment_hash(cell+vec3(1,1,0)),f.x),f.y),
		mix(mix(pigment_hash(cell+vec3(0,0,1)),pigment_hash(cell+vec3(1,0,1)),f.x),
		mix(pigment_hash(cell+vec3(0,1,1)),pigment_hash(cell+vec3(1,1,1)),f.x),f.y),f.z);
}

void vertex() {
	pigment_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 original = texture(color_map, UV);
	if (cutout && original.a * base_color.a < cutoff) { discard; }
	// Read coarse mip levels to suppress baked scratches and grain without changing source art.
	vec3 broad = textureLod(color_map, UV, texture_softness).rgb;
	vec3 paint = mix(broad, original.rgb, 0.12) * base_color.rgb;
	float luminance = dot(paint, vec3(0.299, 0.587, 0.114));
	paint = mix(vec3(luminance), paint, saturation);
	// Group values, not individual RGB channels, so warm wood does not acquire colored contour bands.
	float value = max(dot(paint, vec3(0.299, 0.587, 0.114)), 0.025);
	float grouped = floor(value * color_steps + 0.5) / color_steps;
	paint *= mix(1.0, max(grouped,0.035)/value, 0.35);
	float strokes = brush_noise(pigment_position*vec3(5.0,15.0,5.0));
	float wash = brush_noise(pigment_position*1.8);
	vec3 stained = paint*mix(vec3(0.84,0.76,0.89),vec3(1.14,1.02,0.81),wash);
	stained *= 0.92+0.16*strokes;
	// Uneven dry pigment on a fine paper tooth, anchored to the surface.
	float tooth = brush_noise(pigment_position*110.0);
	float fibre = brush_noise(pigment_position*vec3(160.0,22.0,160.0));
	float dry_pigment = smoothstep(0.48,0.76,tooth*0.65+fibre*0.35);
	stained *= 0.94+0.12*tooth;
	stained = mix(stained,stained*0.65+vec3(0.18,0.145,0.095),dry_pigment*0.18);
	paint = mix(paint,stained,storybook_strength);
	float pigment = sin(pigment_position.x*8.0 + sin(pigment_position.y*5.0))
		* sin(pigment_position.z*6.0 + pigment_position.y*9.0);
	ALBEDO = clamp(paint * (0.97 + 0.025*pigment), vec3(0.015), vec3(0.88));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = ALBEDO * shadow_tint * 0.10;
}

void light() {
	float facing = max(dot(NORMAL, LIGHT), 0.0);
	facing += (brush_noise(pigment_position*8.0)-0.5)*0.12*storybook_strength;
	float brush_shade = 0.22 + 0.38*smoothstep(0.16,0.27,facing)
		+ 0.40*smoothstep(0.62,0.74,facing);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * brush_shade / PI;
}
