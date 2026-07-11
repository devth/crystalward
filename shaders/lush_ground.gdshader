shader_type canvas_item;

// Spec art dir: Dark Crystal + Legend — warm amber light vs cold violet night.
// Moss, mist, crystal flecks; soft dark fairy-tale forest (not flat dull green).
uniform vec4 col_shadow : source_color = vec4(0.04, 0.05, 0.09, 1.0);
uniform vec4 col_deep : source_color = vec4(0.06, 0.10, 0.12, 1.0);
uniform vec4 col_mid : source_color = vec4(0.12, 0.22, 0.20, 1.0);
uniform vec4 col_lit : source_color = vec4(0.22, 0.38, 0.30, 1.0);
uniform vec4 col_moss_gold : source_color = vec4(0.32, 0.42, 0.22, 1.0);
uniform vec4 col_mist : source_color = vec4(0.32, 0.22, 0.48, 1.0);
uniform vec4 col_amber : source_color = vec4(0.85, 0.65, 0.28, 1.0);
uniform vec4 col_cyan : source_color = vec4(0.45, 0.85, 0.9, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 5.0;
uniform float time_scale : hint_range(0.0, 1.0) = 0.025;

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
		p *= 2.08;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * scale;
	uv += vec2(TIME * time_scale * 0.05, TIME * time_scale * -0.03);
	float n = fbm(uv);
	float n2 = fbm(uv * 1.9 + 3.0);
	float n3 = fbm(uv * 0.35 - 1.5);
	float n4 = fbm(uv * 3.2 + TIME * time_scale);

	// Living moss carpet
	vec3 col = mix(col_deep.rgb, col_mid.rgb, smoothstep(0.22, 0.68, n));
	col = mix(col, col_lit.rgb, smoothstep(0.5, 0.92, n2) * 0.4);
	// Golden-moss Legend highlights
	col = mix(col, col_moss_gold.rgb, smoothstep(0.72, 0.95, n2) * 0.22);
	// Deep shadow pools
	col = mix(col, col_shadow.rgb, smoothstep(0.45, 1.0, n3) * 0.5);
	// Violet night mist drifts (title atmosphere)
	float mist = smoothstep(0.55, 0.92, n3) * (0.25 + 0.15 * n4);
	col = mix(col, col_mist.rgb, mist);

	// Ethereal crystal flecks — sparse cyan / amber motes in the ground
	float fleck = step(0.988, hash(floor(UV * 160.0 + vec2(2.0, 7.0))));
	float fleck_amber = step(0.991, hash(floor(UV * 140.0 + vec2(9.0, 1.0))));
	col = mix(col, col_cyan.rgb, fleck * 0.55);
	col = mix(col, col_amber.rgb, fleck_amber * 0.5);

	// Soft grain
	col += (hash(floor(UV * 100.0)) - 0.5) * 0.035;

	// Slight vignette toward UV edges for depth
	float edge = length(UV - 0.5);
	col *= 1.0 - edge * 0.12;

	COLOR = vec4(col, 1.0);
}
