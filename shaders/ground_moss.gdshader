shader_type canvas_item;

uniform vec4 col_dark : source_color = vec4(0.06, 0.08, 0.1, 1.0);
uniform vec4 col_mid : source_color = vec4(0.12, 0.18, 0.15, 1.0);
uniform vec4 col_lit : source_color = vec4(0.18, 0.28, 0.22, 1.0);
uniform vec4 col_purple : source_color = vec4(0.16, 0.1, 0.22, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 12.0;
uniform float time_scale : hint_range(0.0, 1.0) = 0.08;

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
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.05;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * scale;
	uv += vec2(TIME * time_scale * 0.15, TIME * time_scale * -0.08);
	float n = fbm(uv);
	float n2 = fbm(uv * 1.7 + 10.0);

	vec3 col = mix(col_dark.rgb, col_mid.rgb, n);
	col = mix(col, col_lit.rgb, smoothstep(0.45, 0.85, n2) * 0.55);
	col = mix(col, col_purple.rgb, smoothstep(0.55, 0.9, n) * 0.35);

	// Subtle speckles (moss / ash)
	float spec = step(0.92, hash(floor(UV * 180.0)));
	col += vec3(0.15, 0.25, 0.18) * spec * 0.35;

	COLOR = vec4(col, 1.0);
}
