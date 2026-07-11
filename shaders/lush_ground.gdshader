shader_type canvas_item;

// Dark Crystal + Legend night forest: moss, dirt, rock, mist, crystal flecks.
// Macro patches so the camera sees real material variety, not flat carpet.

uniform vec4 col_shadow : source_color = vec4(0.035, 0.04, 0.07, 1.0);
uniform vec4 col_deep : source_color = vec4(0.05, 0.10, 0.09, 1.0);
uniform vec4 col_mid : source_color = vec4(0.11, 0.24, 0.18, 1.0);
uniform vec4 col_lit : source_color = vec4(0.20, 0.40, 0.28, 1.0);
uniform vec4 col_moss_gold : source_color = vec4(0.34, 0.44, 0.20, 1.0);
uniform vec4 col_dirt_dark : source_color = vec4(0.10, 0.07, 0.06, 1.0);
uniform vec4 col_dirt : source_color = vec4(0.22, 0.14, 0.10, 1.0);
uniform vec4 col_dirt_lit : source_color = vec4(0.34, 0.24, 0.16, 1.0);
uniform vec4 col_rock : source_color = vec4(0.14, 0.13, 0.18, 1.0);
uniform vec4 col_rock_lit : source_color = vec4(0.28, 0.26, 0.34, 1.0);
uniform vec4 col_mist : source_color = vec4(0.34, 0.24, 0.50, 1.0);
uniform vec4 col_amber : source_color = vec4(0.90, 0.68, 0.30, 1.0);
uniform vec4 col_cyan : source_color = vec4(0.48, 0.90, 0.92, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 8.0;
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
	mat2 m = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = m * p;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * scale;
	// Slow drift
	uv += vec2(TIME * time_scale * 0.04, TIME * time_scale * -0.025);

	// Domain warp for organic patches
	vec2 warp = vec2(fbm(uv * 0.55 + 2.0), fbm(uv * 0.55 - 4.0));
	vec2 uww = uv + warp * 1.35;

	float macro = fbm(uww * 0.22);
	float n = fbm(uww);
	float n2 = fbm(uww * 2.1 + 3.0);
	float n3 = fbm(uww * 0.4 - 1.5);
	float fine = fbm(uww * 5.5 + TIME * time_scale * 0.5);
	float blades = fbm(vec2(uww.x * 7.0, uww.y * 2.2));

	// Biome masks from macro noise
	float rock_m = smoothstep(0.72, 0.88, macro) * smoothstep(0.4, 0.75, n2);
	float dirt_m = smoothstep(0.28, 0.52, macro) * (1.0 - rock_m) * (0.55 + 0.45 * n3);
	float grass_m = clamp(1.0 - dirt_m - rock_m, 0.0, 1.0);

	// --- Materials ---
	// Moss / grass carpet with blade-ish streaking
	vec3 grass = mix(col_deep.rgb, col_mid.rgb, smoothstep(0.2, 0.7, n));
	grass = mix(grass, col_lit.rgb, smoothstep(0.45, 0.95, n2) * 0.45);
	grass = mix(grass, col_moss_gold.rgb, smoothstep(0.7, 0.95, n2) * 0.28);
	grass = mix(grass, grass * 1.15, smoothstep(0.55, 0.9, blades) * 0.18);
	// Fine blade speckles
	float blade_speck = step(0.82, hash(floor(uww * 48.0)));
	grass = mix(grass, col_lit.rgb * 1.1, blade_speck * 0.12 * grass_m);

	// Packed dirt / soil
	vec3 dirt = mix(col_dirt_dark.rgb, col_dirt.rgb, smoothstep(0.25, 0.75, n));
	dirt = mix(dirt, col_dirt_lit.rgb, smoothstep(0.55, 0.95, fine) * 0.35);
	// Pebbles in dirt
	float pebble = step(0.93, hash(floor(uww * 36.0 + 5.0)));
	dirt = mix(dirt, col_rock_lit.rgb * 0.7, pebble * 0.45);

	// Stone / rock slabs
	vec3 rock = mix(col_rock.rgb, col_rock_lit.rgb, smoothstep(0.35, 0.85, n2));
	// Cracks
	float crack = abs(n - 0.5) * 2.0;
	rock = mix(rock, col_shadow.rgb, smoothstep(0.75, 0.95, crack) * 0.35);
	float grit = step(0.88, hash(floor(uww * 64.0)));
	rock = mix(rock, col_rock_lit.rgb * 1.15, grit * 0.2);

	vec3 col = grass * grass_m + dirt * dirt_m + rock * rock_m;

	// Shadow pools in low macro
	col = mix(col, col_shadow.rgb, smoothstep(0.55, 1.0, n3) * 0.42);

	// Violet night mist drifts
	float mist = smoothstep(0.58, 0.94, n3) * (0.22 + 0.18 * fine);
	col = mix(col, col_mist.rgb, mist);

	// Ethereal crystal flecks in ground
	float fleck = step(0.986, hash(floor(UV * 190.0 + vec2(2.0, 7.0))));
	float fleck_a = step(0.990, hash(floor(UV * 165.0 + vec2(9.0, 1.0))));
	col = mix(col, col_cyan.rgb, fleck * 0.6);
	col = mix(col, col_amber.rgb, fleck_a * 0.55);

	// Soft film grain
	col += (hash(floor(UV * 140.0 + TIME * 0.01)) - 0.5) * 0.028;

	// Gentle vignette
	float edge = length(UV - 0.5);
	col *= 1.0 - edge * 0.14;

	// Slight contrast lift so materials separate on screen
	col = (col - 0.5) * 1.08 + 0.5;
	col = clamp(col, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
