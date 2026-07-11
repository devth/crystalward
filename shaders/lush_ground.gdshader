shader_type canvas_item;

// Ethereal glade floor — soft sage, champagne gold, lilac mist, pastel shimmer.
// Kept readable (clear midtones) so towers/monsters stay sharp on top.

uniform vec4 col_shadow : source_color = vec4(0.12, 0.10, 0.16, 1.0);
uniform vec4 col_deep : source_color = vec4(0.18, 0.28, 0.24, 1.0);
uniform vec4 col_mid : source_color = vec4(0.32, 0.48, 0.40, 1.0);
uniform vec4 col_lit : source_color = vec4(0.52, 0.68, 0.52, 1.0);
uniform vec4 col_moss_gold : source_color = vec4(0.72, 0.68, 0.38, 1.0);
uniform vec4 col_lush : source_color = vec4(0.42, 0.62, 0.48, 1.0);
uniform vec4 col_blush : source_color = vec4(0.78, 0.55, 0.68, 1.0);
uniform vec4 col_lilac : source_color = vec4(0.62, 0.55, 0.82, 1.0);
uniform vec4 col_dirt_dark : source_color = vec4(0.22, 0.16, 0.14, 1.0);
uniform vec4 col_dirt : source_color = vec4(0.42, 0.32, 0.26, 1.0);
uniform vec4 col_dirt_lit : source_color = vec4(0.58, 0.48, 0.36, 1.0);
uniform vec4 col_rock : source_color = vec4(0.28, 0.26, 0.36, 1.0);
uniform vec4 col_rock_lit : source_color = vec4(0.48, 0.46, 0.58, 1.0);
uniform vec4 col_mist : source_color = vec4(0.72, 0.62, 0.88, 1.0);
uniform vec4 col_water : source_color = vec4(0.35, 0.55, 0.68, 1.0);
uniform vec4 col_amber : source_color = vec4(0.96, 0.82, 0.48, 1.0);
uniform vec4 col_cyan : source_color = vec4(0.62, 0.92, 0.95, 1.0);
uniform vec4 col_pearl : source_color = vec4(0.92, 0.88, 0.98, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 12.0;
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
	mat2 m = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));
	for (int i = 0; i < 6; i++) {
		v += a * noise(p);
		p = m * p;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * scale;
	uv += vec2(TIME * time_scale * 0.028, TIME * time_scale * -0.018);

	vec2 warp = vec2(fbm(uv * 0.5 + 2.0), fbm(uv * 0.5 - 4.0));
	vec2 uww = uv + warp * 1.6;

	float elev = fbm(uww * 0.16);
	elev = elev * 0.65 + fbm(uww * 0.48) * 0.35;

	float macro = elev;
	float n = fbm(uww);
	float n2 = fbm(uww * 2.2 + 3.0);
	float n3 = fbm(uww * 0.38 - 1.5);
	float fine = fbm(uww * 6.0 + TIME * time_scale * 0.35);
	float blades = fbm(vec2(uww.x * 9.0, uww.y * 2.6));
	float canopy = fbm(uww * 1.1 + 7.0);
	// Soft shimmer field (pastels, not noise haze)
	float shimmer = fbm(uww * 3.5 + TIME * time_scale * 1.2);

	float valley = smoothstep(0.48, 0.2, elev);
	float ridge = smoothstep(0.58, 0.86, elev);
	float rock_m = ridge * smoothstep(0.4, 0.78, n2) * 0.55;
	float dirt_m = smoothstep(0.32, 0.58, macro) * (1.0 - rock_m) * (0.35 + 0.4 * n3) * 0.55;
	float grass_m = clamp(1.0 - dirt_m - rock_m, 0.0, 1.0);
	grass_m = clamp(grass_m + 0.28, 0.0, 1.0);
	dirt_m *= 0.65;
	rock_m *= 0.75;

	// Soft sage / mint meadow
	vec3 grass = mix(col_deep.rgb, col_mid.rgb, smoothstep(0.12, 0.7, n));
	grass = mix(grass, col_lush.rgb, smoothstep(0.3, 0.85, canopy) * 0.5);
	grass = mix(grass, col_lit.rgb, smoothstep(0.38, 0.95, n2) * 0.55);
	// Champagne gold moss patches
	grass = mix(grass, col_moss_gold.rgb, smoothstep(0.58, 0.95, n2) * 0.32);
	// Soft blush / lilac meadow flecks
	grass = mix(grass, col_blush.rgb, smoothstep(0.72, 0.98, n3) * 0.12);
	grass = mix(grass, col_lilac.rgb, smoothstep(0.78, 0.99, fine) * 0.1);
	grass = mix(grass, grass * 1.12, smoothstep(0.48, 0.92, blades) * 0.2);
	float blade_speck = step(0.76, hash(floor(uww * 64.0)));
	grass = mix(grass, col_lit.rgb * 1.15, blade_speck * 0.14 * grass_m);
	float gold_dot = step(0.9, hash(floor(uww * 32.0 + 3.0)));
	grass = mix(grass, col_amber.rgb * 0.95, gold_dot * 0.14 * grass_m);

	// Warm rose-dirt
	vec3 dirt = mix(col_dirt_dark.rgb, col_dirt.rgb, smoothstep(0.2, 0.75, n));
	dirt = mix(dirt, col_dirt_lit.rgb, smoothstep(0.55, 0.95, fine) * 0.45);
	float pebble = step(0.92, hash(floor(uww * 40.0 + 5.0)));
	dirt = mix(dirt, col_rock_lit.rgb * 0.85, pebble * 0.4);

	// Soft lavender rock
	vec3 rock = mix(col_rock.rgb, col_rock_lit.rgb, smoothstep(0.3, 0.85, n2));
	float crack = abs(n - 0.5) * 2.0;
	rock = mix(rock, col_shadow.rgb, smoothstep(0.72, 0.95, crack) * 0.28);

	vec3 col = grass * grass_m + dirt * dirt_m + rock * rock_m;

	// Gentle elevation (don't crush to black)
	col *= 0.78 + elev * 0.42;
	float gx = fbm(uww + vec2(0.08, 0.0)) - fbm(uww - vec2(0.08, 0.0));
	float gy = fbm(uww + vec2(0.0, 0.08)) - fbm(uww - vec2(0.0, 0.08));
	float slope = clamp(0.58 + gx * 1.4 - gy * 0.7, 0.62, 1.2);
	col *= slope;

	// Soft water / lilac valleys
	col = mix(col, mix(col, col_water.rgb, 0.28), valley * 0.35);
	col = mix(col, col_lilac.rgb, valley * 0.08);
	// Golden meadow belts
	col = mix(col, col_lit.rgb, (1.0 - valley) * (1.0 - ridge) * 0.12);
	col = mix(col, col_moss_gold.rgb, (1.0 - valley) * (1.0 - ridge) * smoothstep(0.45, 0.85, n) * 0.1);

	// Soft shadow pools (pastel, not black)
	col = mix(col, col_shadow.rgb, smoothstep(0.6, 1.0, n3) * 0.16);

	// Lilac pearl mist — light wash, not fog
	float mist = smoothstep(0.62, 0.96, n3) * (0.1 + 0.1 * fine);
	col = mix(col, col_mist.rgb, mist * 0.55);
	col = mix(col, col_pearl.rgb, mist * 0.12);

	// Animated pastel shimmer (gold + cyan + pearl flecks)
	float shimmer_wave = 0.5 + 0.5 * sin(TIME * 1.4 + shimmer * 6.28);
	float fleck = step(0.978, hash(floor(UV * 210.0 + vec2(2.0, 7.0) + TIME * 0.15)));
	float fleck_a = step(0.982, hash(floor(UV * 185.0 + vec2(9.0, 1.0) - TIME * 0.12)));
	float fleck_p = step(0.986, hash(floor(UV * 160.0 + vec2(4.0, 11.0))));
	col = mix(col, col_cyan.rgb, fleck * 0.5 * shimmer_wave);
	col = mix(col, col_amber.rgb, fleck_a * 0.55 * (1.0 - shimmer_wave * 0.3));
	col = mix(col, col_pearl.rgb, fleck_p * 0.4);

	// Soft gold bloom patches
	float gold_field = smoothstep(0.7, 0.95, shimmer) * (0.06 + 0.05 * sin(TIME * 0.8 + n * 4.0));
	col = mix(col, col_amber.rgb, gold_field);

	col += (hash(floor(UV * 150.0)) - 0.5) * 0.018;
	float edge = length(UV - 0.5);
	col *= 1.0 - edge * 0.05;
	// Lift midtones — bright ethereal, still clear
	col = (col - 0.5) * 1.06 + 0.56;
	col = clamp(col, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
