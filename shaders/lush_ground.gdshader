shader_type canvas_item;

// Lush readable ground — warm greens + soft purple shadow (PJ Monsters readability).
uniform vec4 col_shadow : source_color = vec4(0.12, 0.1, 0.18, 1.0);
uniform vec4 col_deep : source_color = vec4(0.18, 0.32, 0.22, 1.0);
uniform vec4 col_mid : source_color = vec4(0.28, 0.48, 0.32, 1.0);
uniform vec4 col_lit : source_color = vec4(0.42, 0.62, 0.38, 1.0);
uniform vec4 col_flower : source_color = vec4(0.65, 0.4, 0.75, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 9.0;
uniform float time_scale : hint_range(0.0, 1.0) = 0.05;

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
		p *= 2.1;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * scale;
	uv += vec2(TIME * time_scale * 0.1, TIME * time_scale * -0.06);
	float n = fbm(uv);
	float n2 = fbm(uv * 2.3 + 4.0);
	float n3 = fbm(uv * 0.5 - 2.0);

	vec3 col = mix(col_deep.rgb, col_mid.rgb, smoothstep(0.25, 0.7, n));
	col = mix(col, col_lit.rgb, smoothstep(0.55, 0.9, n2) * 0.55);
	col = mix(col, col_shadow.rgb, smoothstep(0.6, 1.0, n3) * 0.35);

	// Flower / pollen speckles
	float flower = step(0.965, hash(floor(UV * 140.0 + vec2(3.0, 7.0))));
	col = mix(col, col_flower.rgb, flower * 0.85);
	float pollen = step(0.98, hash(floor(UV * 220.0)));
	col += vec3(0.9, 0.85, 0.4) * pollen * 0.35;

	// Soft vignette toward edges of UV space (per tile feel)
	float edge = length(UV - 0.5);
	col *= 1.0 - edge * 0.08;

	COLOR = vec4(col, 1.0);
}
