shader_type canvas_item;
render_mode unshaded;
uniform float glow_strength : hint_range(0.0,2.0) = 0.85;
uniform float softness : hint_range(0.0,1.0) = 0.17;
uniform float mist_strength : hint_range(0.0,0.3) = 0.07;
uniform float storybook_strength = 0.0;
uniform float paper_grain = 0.018;

float paper_hash(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float paper_noise(vec2 p) {
	vec2 i=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(paper_hash(i),paper_hash(i+vec2(1,0)),f.x),
		mix(paper_hash(i+vec2(0,1)),paper_hash(i+vec2(1,1)),f.x),f.y);
}

void fragment() {
	vec4 original = texture(TEXTURE,UV);
	vec2 pixel = TEXTURE_PIXEL_SIZE;
	vec3 soft = texture(TEXTURE,UV+pixel*vec2(1.5,0.0)).rgb;
	soft += texture(TEXTURE,UV-pixel*vec2(1.5,0.0)).rgb;
	soft += texture(TEXTURE,UV+pixel*vec2(0.0,1.5)).rgb;
	soft += texture(TEXTURE,UV-pixel*vec2(0.0,1.5)).rgb;
	vec3 glow = vec3(0.0);
	float total_weight = 0.0;
	for (int x=-4;x<=4;x++) {
		for (int y=-4;y<=4;y++) {
			vec2 offset = vec2(float(x),float(y));
			float weight = exp(-dot(offset,offset)/8.0);
			vec3 sample_color = texture(TEXTURE,UV+offset*pixel*3.0).rgb;
			float brightness = max(sample_color.r,max(sample_color.g,sample_color.b));
			glow += sample_color*smoothstep(0.72,0.99,brightness)*weight;
			total_weight += weight;
		}
	}
	glow /= total_weight;
	vec3 color = mix(original.rgb,soft*0.25,softness);
	color += glow*glow_strength*vec3(1.0,0.88,0.71);
	float drift = 0.5+0.25*sin(UV.x*12.0+UV.y*7.0+TIME*0.12)
		+0.25*sin(UV.x*7.0-UV.y*14.0-TIME*0.09);
	float low_mist = smoothstep(0.32,1.0,UV.y)*drift*mist_strength;
	color = mix(color,vec3(0.47,0.58,0.61),low_mist);
	float edge = smoothstep(0.28,0.8,length((UV-0.5)*vec2(1.0,0.8)));
	color *= 1.0-edge*0.20;
	// Split-tone the illustration without washing out its deepest ink values.
	float value = dot(color,vec3(0.299,0.587,0.114));
	float shadow = 1.0-smoothstep(0.08,0.5,value);
	float lit = smoothstep(0.3,0.85,value);
	vec3 graded = color*mix(vec3(0.94,0.80,1.02),vec3(1.09,1.01,0.84),lit);
	graded = mix(graded,vec3(0.085,0.048,0.088),shadow*0.14);
	graded = max((graded-0.17)*1.10+0.17,vec3(0.0));
	vec2 paper_pixel = floor(UV/pixel);
	// Irregular paper fibres at several scales, without smearing the picture.
	float grain = paper_noise(paper_pixel*0.72)-0.5;
	float fibres = paper_noise(paper_pixel*vec2(0.13,0.85))-0.5;
	float pulp = paper_noise(paper_pixel*0.045)-0.5;
	float tooth = grain*0.65+fibres*0.55+pulp*0.35;
	graded *= 1.0+tooth*paper_grain*4.0;
	graded += tooth*paper_grain*0.65;
	// A restrained dark ink accent on existing local boundaries.
	vec3 neighbour = soft*0.25;
	float ink_edge = max(dot(neighbour-original.rgb,vec3(0.299,0.587,0.114))-0.012,0.0);
	graded *= 1.0-min(ink_edge*1.8,0.22);
	color = mix(color,graded,storybook_strength);
	COLOR = vec4(color,original.a);
}
