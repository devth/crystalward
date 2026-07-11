shader_type canvas_item;

// Lush night forest floor — rich moss, dirt, rock, water valleys, elevation lighting.

uniform vec4 col_shadow : source_color = vec4(0.03, 0.05, 0.06, 1.0);
uniform vec4 col_deep : source_color = vec4(0.05, 0.16, 0.09, 1.0);
uniform vec4 col_mid : source_color = vec4(0.12, 0.34, 0.18, 1.0);
uniform vec4 col_lit : source_color = vec4(0.28, 0.56, 0.30, 1.0);
uniform vec4 col_moss_gold : source_color = vec4(0.42, 0.56, 0.20, 1.0);
uniform vec4 col_lush : source_color = vec4(0.18, 0.48, 0.26, 1.0);
uniform vec4 col_dirt_dark : source_color = vec4(0.09, 0.06, 0.05, 1.0);
uniform vec4 col_dirt : source_color = vec4(0.24, 0.16, 0.10, 1.0);
uniform vec4 col_dirt_lit : source_color = vec4(0.38, 0.28, 0.16, 1.0);
uniform vec4 col_rock : source_color = vec4(0.13, 0.12, 0.17, 1.0);
uniform vec4 col_rock_lit : source_color = vec4(0.30, 0.28, 0.36, 1.0);
uniform vec4 col_mist : source_color = vec4(0.30, 0.22, 0.46, 1.0);
uniform vec4 col_water : source_color = vec4(0.10, 0.24, 0.34, 1.0);
uniform vec4 col_amber : source_color = vec4(0.90, 0.68, 0.30, 1.0);
uniform vec4 col_cyan : source_color = vec4(0.48, 0.90, 0.92, 1.0);
uniform float scale : hint_range(1.0, 40.0) = 12.0;
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
	for (int i = 0; i < 6; i++) {
		v += a * noise(p);
		p = m * p;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * scale;
	uv += vec2(TIME * time_scale * 0.03, TIME * time_scale * -0.02);

	vec2 warp = vec2(fbm(uv * 0.5 + 2.0), fbm(uv * 0.5 - 4.0));
	vec2 uww = uv + warp * 1.8;

	// Elevation field — drives lighting & material
	float elev = fbm(uww * 0.16);
	elev = elev * 0.65 + fbm(uww * 0.48) * 0.35;

	float macro = elev;
	float n = fbm(uww);
	float n2 = fbm(uww * 2.2 + 3.0);
	float n3 = fbm(uww * 0.38 - 1.5);
	float fine = fbm(uww * 6.0 + TIME * time_scale * 0.4);
	float blades = fbm(vec2(uww.x * 9.0, uww.y * 2.6));
	float canopy = fbm(uww * 1.1 + 7.0);

	// Biomes by elevation + macro
	float valley = smoothstep(0.48, 0.2, elev);   // low = moist
	float ridge = smoothstep(0.58, 0.86, elev);    // high = rock/dry
	float rock_m = ridge * smoothstep(0.4, 0.78, n2) * 0.75;
	float dirt_m = smoothstep(0.32, 0.58, macro) * (1.0 - rock_m) * (0.4 + 0.45 * n3) * 0.7;
	float grass_m = clamp(1.0 - dirt_m - rock_m, 0.0, 1.0);
	// Strong grass bias for lush read
	grass_m = clamp(grass_m + 0.22, 0.0, 1.0);
	dirt_m *= 0.72;
	rock_m *= 0.85;

	// Lush moss / grass layers
	vec3 grass = mix(col_deep.rgb, col_mid.rgb, smoothstep(0.12, 0.7, n));
	grass = mix(grass, col_lush.rgb, smoothstep(0.3, 0.85, canopy) * 0.55);
	grass = mix(grass, col_lit.rgb, smoothstep(0.38, 0.95, n2) * 0.6);
	grass = mix(grass, col_moss_gold.rgb, smoothstep(0.62, 0.95, n2) * 0.38);
	grass = mix(grass, grass * 1.22, smoothstep(0.48, 0.92, blades) * 0.28);
	float blade_speck = step(0.74, hash(floor(uww * 64.0)));
	grass = mix(grass, col_lit.rgb * 1.2, blade_speck * 0.2 * grass_m);
	// Dense undergrowth speckles
	float moss_dot = step(0.88, hash(floor(uww * 28.0 + 3.0)));
	grass = mix(grass, col_moss_gold.rgb * 0.95, moss_dot * 0.18 * grass_m);

	// Dirt
	vec3 dirt = mix(col_dirt_dark.rgb, col_dirt.rgb, smoothstep(0.2, 0.75, n));
	dirt = mix(dirt, col_dirt_lit.rgb, smoothstep(0.55, 0.95, fine) * 0.4);
	float pebble = step(0.92, hash(floor(uww * 40.0 + 5.0)));
	dirt = mix(dirt, col_rock_lit.rgb * 0.75, pebble * 0.5);

	// Rock
	vec3 rock = mix(col_rock.rgb, col_rock_lit.rgb, smoothstep(0.3, 0.85, n2));
	float crack = abs(n - 0.5) * 2.0;
	rock = mix(rock, col_shadow.rgb, smoothstep(0.72, 0.95, crack) * 0.4);

	vec3 col = grass * grass_m + dirt * dirt_m + rock * rock_m;

	// Elevation lighting: brighten ridges, darken valleys (stronger contrast)
	col *= 0.65 + elev * 0.7;
	// Slope shade from noise gradient
	float gx = fbm(uww + vec2(0.08, 0.0)) - fbm(uww - vec2(0.08, 0.0));
	float gy = fbm(uww + vec2(0.0, 0.08)) - fbm(uww - vec2(0.0, 0.08));
	float slope = clamp(0.48 + gx * 2.0 - gy * 1.0, 0.5, 1.3);
	col *= slope;

	// Moist valley tint (lake-adjacent lush)
	col = mix(col, mix(col, col_water.rgb, 0.4), valley * 0.5);
	// Extra green mid elevations — meadow belts
	col = mix(col, col_lit.rgb, (1.0 - valley) * (1.0 - ridge) * 0.18);
	col = mix(col, col_lush.rgb, (1.0 - valley) * (1.0 - ridge) * smoothstep(0.4, 0.8, n) * 0.12);

	// Shadow pools (slightly lighter so land stays verdant)
	col = mix(col, col_shadow.rgb, smoothstep(0.55, 1.0, n3) * 0.28);

	// Violet night mist
	float mist = smoothstep(0.58, 0.95, n3) * (0.16 + 0.14 * fine);
	col = mix(col, col_mist.rgb, mist);

	// Crystal flecks
	float fleck = step(0.982, hash(floor(UV * 200.0 + vec2(2.0, 7.0))));
	float fleck_a = step(0.986, hash(floor(UV * 175.0 + vec2(9.0, 1.0))));
	col = mix(col, col_cyan.rgb, fleck * 0.55);
	col = mix(col, col_amber.rgb, fleck_a * 0.5);

	col += (hash(floor(UV * 150.0)) - 0.5) * 0.025;
	float edge = length(UV - 0.5);
	col *= 1.0 - edge * 0.08;
	// Lift midtones for verdant night-forest
	col = (col - 0.5) * 1.14 + 0.52;
	col = clamp(col, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
