shader_type canvas_item;

// Cohesive dark-forest floor — soft moss variation, no candy speckles.
uniform vec4 col_shadow : source_color = vec4(0.08, 0.12, 0.10, 1.0);
uniform vec4 col_deep : source_color = vec4(0.12, 0.26, 0.18, 1.0);
uniform vec4 col_mid : source_color = vec4(0.22, 0.40, 0.26, 1.0);
uniform vec4 col_lit : source_color = vec4(0.36, 0.52, 0.32, 1.0);
uniform vec4 col_dirt : source_color = vec4(0.28, 0.24, 0.16, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 6.0;
uniform float time_scale : hint_range(0.0, 1.0) = 0.02;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.05;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * scale;
	// Very slow drift — living forest, not a lava lamp
	uv += vec2(TIME * time_scale * 0.04, TIME * time_scale * -0.03);
	float n = fbm(uv);
	float n2 = fbm(uv * 1.8 + 3.0);
	float n3 = fbm(uv * 0.45 - 1.5);

	vec3 col = mix(col_deep.rgb, col_mid.rgb, smoothstep(0.28, 0.72, n));
	col = mix(col, col_lit.rgb, smoothstep(0.6, 0.95, n2) * 0.35);
	col = mix(col, col_shadow.rgb, smoothstep(0.55, 1.0, n3) * 0.4);
	// Occasional bare earth patches
	float dirt = smoothstep(0.78, 0.92, n2) * step(0.72, hash(floor(uv * 3.0)));
	col = mix(col, col_dirt.rgb, dirt * 0.45);

	// Subtle micro grain (not flower confetti)
	float grain = (hash(floor(UV * 90.0)) - 0.5) * 0.04;
	col += grain;

	COLOR = vec4(col, 1.0);
}
