shader_type canvas_item;

// Title-screen forest floor: deep teal-moss under purple mist.
uniform vec4 col_shadow : source_color = vec4(0.05, 0.07, 0.1, 1.0);
uniform vec4 col_deep : source_color = vec4(0.08, 0.14, 0.14, 1.0);
uniform vec4 col_mid : source_color = vec4(0.14, 0.26, 0.22, 1.0);
uniform vec4 col_lit : source_color = vec4(0.22, 0.38, 0.32, 1.0);
uniform vec4 col_mist : source_color = vec4(0.28, 0.2, 0.38, 1.0);
uniform vec4 col_dirt : source_color = vec4(0.18, 0.14, 0.16, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 5.5;
uniform float time_scale : hint_range(0.0, 1.0) = 0.015;

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
	uv += vec2(TIME * time_scale * 0.03, TIME * time_scale * -0.02);
	float n = fbm(uv);
	float n2 = fbm(uv * 1.7 + 2.5);
	float n3 = fbm(uv * 0.4 - 1.2);

	vec3 col = mix(col_deep.rgb, col_mid.rgb, smoothstep(0.25, 0.7, n));
	col = mix(col, col_lit.rgb, smoothstep(0.55, 0.95, n2) * 0.3);
	col = mix(col, col_shadow.rgb, smoothstep(0.5, 1.0, n3) * 0.45);
	// Purple mist pools (title screen atmosphere)
	float mist = smoothstep(0.65, 0.95, n3) * 0.35;
	col = mix(col, col_mist.rgb, mist);
	// Bare earth / root soil
	float dirt = smoothstep(0.8, 0.95, n2) * step(0.75, hash(floor(uv * 2.5)));
	col = mix(col, col_dirt.rgb, dirt * 0.4);

	float grain = (hash(floor(UV * 80.0)) - 0.5) * 0.03;
	col += grain;

	COLOR = vec4(col, 1.0);
}
