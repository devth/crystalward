shader_type canvas_item;

// Lifelike ground floor — clear materials, strong altitude light, readable detail.
// Grass, dirt, rock, wet basins read at play zoom without watercolor wash-out.

uniform vec4 col_shadow : source_color = vec4(0.10, 0.12, 0.08, 1.0);
uniform vec4 col_grass_deep : source_color = vec4(0.14, 0.32, 0.16, 1.0);
uniform vec4 col_grass : source_color = vec4(0.28, 0.50, 0.24, 1.0);
uniform vec4 col_grass_lit : source_color = vec4(0.48, 0.68, 0.32, 1.0);
uniform vec4 col_dirt_dark : source_color = vec4(0.26, 0.22, 0.14, 1.0);
uniform vec4 col_dirt : source_color = vec4(0.44, 0.38, 0.26, 1.0);
uniform vec4 col_dirt_lit : source_color = vec4(0.56, 0.50, 0.34, 1.0);
uniform vec4 col_sand : source_color = vec4(0.62, 0.56, 0.40, 1.0);
uniform vec4 col_rock : source_color = vec4(0.38, 0.38, 0.36, 1.0);
uniform vec4 col_rock_lit : source_color = vec4(0.54, 0.54, 0.50, 1.0);
uniform vec4 col_wet : source_color = vec4(0.18, 0.34, 0.28, 1.0);
uniform vec4 col_moss : source_color = vec4(0.32, 0.52, 0.26, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 16.0;
uniform float time_scale : hint_range(0.0, 1.0) = 0.008;

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
	uv += vec2(TIME * time_scale * 0.012, TIME * time_scale * -0.008);

	vec2 warp = vec2(fbm(uv * 0.35 + 1.5), fbm(uv * 0.35 - 3.0));
	vec2 uww = uv + warp * 0.85;

	float elev = fbm(uww * 0.07) * 0.45 + fbm(uww * 0.16) * 0.35 + fbm(uww * 0.48) * 0.2;
	float n = fbm(uww);
	float n2 = fbm(uww * 2.1 + 2.5);
	float n3 = fbm(uww * 0.32 - 1.2);
	float fine = fbm(uww * 6.0);
	float grain = fbm(uww * 13.0);
	float micro = fbm(uww * 22.0);

	// Clear material bands
	float rock_m = smoothstep(0.52, 0.82, elev) * smoothstep(0.28, 0.72, n2);
	float sand_m = smoothstep(0.26, 0.48, n3) * (1.0 - rock_m) * smoothstep(0.12, 0.48, elev) * 0.5;
	float dirt_m = smoothstep(0.22, 0.52, elev) * (1.0 - rock_m) * (1.0 - sand_m) * (0.45 + 0.4 * n3);
	float wet_m = smoothstep(0.45, 0.12, elev) * (1.0 - rock_m) * 0.7;
	float grass_m = clamp(1.0 - dirt_m - rock_m - sand_m * 0.65, 0.0, 1.0);

	// Grass with blade grain + moss flecks
	vec3 grass = mix(col_grass_deep.rgb, col_grass.rgb, smoothstep(0.12, 0.72, n));
	grass = mix(grass, col_grass_lit.rgb, smoothstep(0.42, 0.92, n2) * 0.48);
	grass = mix(grass, col_moss.rgb, smoothstep(0.52, 0.92, fine) * 0.28);
	float blade = fbm(vec2(uww.x * 14.0, uww.y * 2.4));
	grass = mix(grass, grass * 1.12, smoothstep(0.48, 0.92, blade) * 0.22);
	// Tuft highlights
	grass += vec3(0.04, 0.06, 0.02) * smoothstep(0.7, 0.95, micro) * 0.5;

	// Packed earth
	vec3 dirt = mix(col_dirt_dark.rgb, col_dirt.rgb, smoothstep(0.18, 0.78, n));
	dirt = mix(dirt, col_dirt_lit.rgb, smoothstep(0.48, 0.92, fine) * 0.4);
	dirt = mix(dirt, dirt * (0.9 + grain * 0.2), 0.55);
	// Pebble flecks
	float pebble = step(0.9, hash(floor(uww * 18.0)));
	dirt = mix(dirt, col_rock.rgb * 0.9, pebble * 0.35);

	// Sand / dry patches
	vec3 sand = mix(col_sand.rgb * 0.88, col_sand.rgb, smoothstep(0.28, 0.82, fine));
	sand = mix(sand, col_dirt_lit.rgb, grain * 0.18);

	// Rock face
	vec3 rock = mix(col_rock.rgb, col_rock_lit.rgb, smoothstep(0.28, 0.88, n2));
	float crack = abs(n - 0.5) * 2.0;
	rock = mix(rock, col_shadow.rgb, smoothstep(0.68, 0.96, crack) * 0.32);
	rock = mix(rock, col_moss.rgb, smoothstep(0.55, 0.9, fine) * 0.18);

	// Wet hollows
	vec3 wet = mix(col_wet.rgb, col_grass_deep.rgb, 0.3);
	wet = mix(wet, wet * 1.08, smoothstep(0.5, 0.9, fine) * 0.15);

	vec3 col = grass * grass_m + dirt * dirt_m + rock * rock_m + sand * sand_m;
	col = mix(col, wet, wet_m * (1.0 - rock_m));

	// Strong altitude lighting — ridges bright, valleys deep
	col *= 0.58 + elev * 0.85;
	float gx = fbm(uww + vec2(0.06, 0.0)) - fbm(uww - vec2(0.06, 0.0));
	float gy = fbm(uww + vec2(0.0, 0.06)) - fbm(uww - vec2(0.0, 0.06));
	float slope = clamp(0.52 + gx * 2.0 - gy * 1.15, 0.5, 1.35);
	col *= slope;

	// Soft contour shade
	float bands = sin(elev * 16.0 + n * 2.0) * 0.5 + 0.5;
	col = mix(col, col * 0.9, bands * 0.1 * smoothstep(0.15, 0.85, abs(elev - 0.5)));

	// Deep shade pools
	col = mix(col, col_shadow.rgb, smoothstep(0.5, 1.0, n3) * (0.14 + wet_m * 0.12));

	// Fine surface grain (soil/grass tooth) — keeps texture clear, not mushy
	col += (hash(floor(UV * 120.0 + grain * 4.0)) - 0.5) * 0.045;
	col = mix(col, col * (0.92 + micro * 0.16), 0.28);

	// Warm rim light on high ground, cool only in deepest hollows
	col = mix(col, col * vec3(1.06, 1.04, 0.94), smoothstep(0.4, 0.88, elev) * 0.16);
	col = mix(col, col * vec3(0.9, 0.92, 0.98), smoothstep(0.35, 0.0, elev) * 0.12);

	// Readable contrast — not watercolor midtone crush
	col = (col - 0.5) * 1.08 + 0.5;
	col = clamp(col, 0.02, 0.98);

	COLOR = vec4(col, 1.0);
}
