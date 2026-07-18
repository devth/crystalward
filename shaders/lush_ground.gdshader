shader_type canvas_item;

// Integrated cover-art landscape floor — fine detail, wet washes, realistic light.
// No prop clutter; the ground itself carries the painting.

// Thra floor — Dark Crystal: deep violet shadow, river-green moss, cool stone
uniform vec4 col_shadow : source_color = vec4(0.10, 0.08, 0.14, 1.0);
uniform vec4 col_grass_deep : source_color = vec4(0.12, 0.22, 0.20, 1.0);
uniform vec4 col_grass : source_color = vec4(0.20, 0.36, 0.30, 1.0);
uniform vec4 col_grass_lit : source_color = vec4(0.32, 0.50, 0.42, 1.0);
uniform vec4 col_dirt_dark : source_color = vec4(0.18, 0.14, 0.16, 1.0);
uniform vec4 col_dirt : source_color = vec4(0.32, 0.28, 0.30, 1.0);
uniform vec4 col_dirt_lit : source_color = vec4(0.44, 0.40, 0.38, 1.0);
uniform vec4 col_sand : source_color = vec4(0.48, 0.42, 0.36, 1.0);
uniform vec4 col_rock : source_color = vec4(0.26, 0.24, 0.34, 1.0);
uniform vec4 col_rock_lit : source_color = vec4(0.40, 0.38, 0.48, 1.0);
uniform vec4 col_wet : source_color = vec4(0.14, 0.24, 0.30, 1.0);
uniform vec4 col_moss : source_color = vec4(0.26, 0.42, 0.36, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 14.0;
uniform float time_scale : hint_range(0.0, 1.0) = 0.01;

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
	// Almost static — subtle drift only
	uv += vec2(TIME * time_scale * 0.015, TIME * time_scale * -0.01);

	vec2 warp = vec2(fbm(uv * 0.4 + 1.5), fbm(uv * 0.4 - 3.0));
	vec2 uww = uv + warp * 1.1;

	// Multi-scale altitude field (matches world height feel)
	float elev = fbm(uww * 0.08) * 0.45 + fbm(uww * 0.18) * 0.35 + fbm(uww * 0.5) * 0.2;
	float n = fbm(uww);
	float n2 = fbm(uww * 2.0 + 2.5);
	float n3 = fbm(uww * 0.35 - 1.2);
	float fine = fbm(uww * 5.5);
	float grain = fbm(uww * 11.0);

	// Material masks by altitude
	float rock_m = smoothstep(0.55, 0.85, elev) * smoothstep(0.3, 0.75, n2);
	float sand_m = smoothstep(0.28, 0.48, n3) * (1.0 - rock_m) * smoothstep(0.15, 0.5, elev) * 0.45;
	float dirt_m = smoothstep(0.25, 0.55, elev) * (1.0 - rock_m) * (1.0 - sand_m) * (0.4 + 0.4 * n3);
	float wet_m = smoothstep(0.48, 0.15, elev) * (1.0 - rock_m) * 0.65; // valleys
	float grass_m = clamp(1.0 - dirt_m - rock_m - sand_m * 0.7, 0.0, 1.0);
	grass_m = clamp(grass_m + 0.1, 0.0, 1.0);
	dirt_m *= 0.88;

	// Grass: soft vertical blade grain
	vec3 grass = mix(col_grass_deep.rgb, col_grass.rgb, smoothstep(0.15, 0.7, n));
	grass = mix(grass, col_grass_lit.rgb, smoothstep(0.45, 0.9, n2) * 0.4);
	grass = mix(grass, col_moss.rgb, smoothstep(0.55, 0.9, fine) * 0.25);
	float blade = fbm(vec2(uww.x * 10.0, uww.y * 2.2));
	grass = mix(grass, grass * 1.08, smoothstep(0.5, 0.9, blade) * 0.15);

	// Dirt: packed earth grain
	vec3 dirt = mix(col_dirt_dark.rgb, col_dirt.rgb, smoothstep(0.2, 0.75, n));
	dirt = mix(dirt, col_dirt_lit.rgb, smoothstep(0.5, 0.9, fine) * 0.35);
	dirt = mix(dirt, dirt * (0.92 + grain * 0.16), 0.5);

	// Sand: shore / dry patches
	vec3 sand = mix(col_sand.rgb * 0.85, col_sand.rgb, smoothstep(0.3, 0.8, fine));
	sand = mix(sand, col_dirt_lit.rgb, grain * 0.2);

	// Rock: cooler stone flecks
	vec3 rock = mix(col_rock.rgb, col_rock_lit.rgb, smoothstep(0.3, 0.85, n2));
	float crack = abs(n - 0.5) * 2.0;
	rock = mix(rock, col_shadow.rgb, smoothstep(0.7, 0.95, crack) * 0.25);

	// Wet ground near valleys
	vec3 wet = mix(col_wet.rgb, col_grass_deep.rgb, 0.35);

	vec3 col = grass * grass_m + dirt * dirt_m + rock * rock_m + sand * sand_m;
	col = mix(col, wet, wet_m * (1.0 - rock_m));

	// Strong altitude lighting: valleys darker, ridges brighter
	col *= 0.62 + elev * 0.7;
	// Slope shade from height gradient
	float gx = fbm(uww + vec2(0.07, 0.0)) - fbm(uww - vec2(0.07, 0.0));
	float gy = fbm(uww + vec2(0.0, 0.07)) - fbm(uww - vec2(0.0, 0.07));
	float slope = clamp(0.55 + gx * 1.8 - gy * 1.0, 0.55, 1.28);
	col *= slope;
	// Soft contour-ish bands (subtle, not stripes)
	float bands = sin(elev * 18.0 + n * 2.0) * 0.5 + 0.5;
	col = mix(col, col * 0.92, bands * 0.08 * smoothstep(0.2, 0.8, abs(elev)));

	// Soft shadow pools in low land
	col = mix(col, col_shadow.rgb, smoothstep(0.55, 1.0, n3) * (0.12 + wet_m * 0.1));

	// Pigment granulation (watercolor paper catching color)
	float gran = fbm(uww * 14.0);
	col = mix(col, col * (0.88 + gran * 0.22), 0.35);
	// Soft wash bleed between materials
	col = mix(col, mix(col_grass.rgb, col_moss.rgb, n2), 0.06);
	// Paper tooth
	col += (hash(floor(UV * 90.0 + gran * 3.0)) - 0.5) * 0.035;
	// Cool violet in deep shade (cover-art shadow)
	col = mix(col, col * vec3(0.85, 0.82, 0.95), smoothstep(0.4, 0.0, elev) * 0.18);
	// Warm parchment lift on high ground
	col = mix(col, col * vec3(1.08, 1.04, 0.92), smoothstep(0.35, 0.85, elev) * 0.12);

	float edge = length(UV - 0.5);
	col *= 1.0 - edge * 0.05;
	// Soft painterly contrast (not crunchy game values)
	col = (col - 0.5) * 0.94 + 0.5;
	col = clamp(col, 0.04, 0.96);

	COLOR = vec4(col, 1.0);
}
