shader_type canvas_item;

// Watercolor / Dark Crystal cover-art grade.
// Soft pigment bleed, paper grain, warm parchment lights + violet shadows.
// Avoids harsh "arcade game" contrast while keeping gameplay readable.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.58;
uniform float bloom_intensity : hint_range(0.0, 2.0) = 0.32;
uniform float saturation : hint_range(0.0, 2.0) = 0.92;
uniform float contrast : hint_range(0.5, 1.5) = 0.94;
uniform vec4 tint : source_color = vec4(1.02, 0.97, 1.04, 1.0);
uniform float gold_lift : hint_range(0.0, 0.25) = 0.04;
uniform float clarity : hint_range(0.0, 1.0) = 0.22;
uniform float paper_grain : hint_range(0.0, 0.2) = 0.055;
uniform float pigment_bleed : hint_range(0.0, 1.0) = 0.45;
uniform float wash_strength : hint_range(0.0, 1.0) = 0.35;

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
	vec2 uv = SCREEN_UV;
	// Soft watercolor warp (very slight) — wet-on-wet edge drift
	float warp_n = fbm(uv * 6.0 + vec2(0.2, 0.7));
	vec2 warp = (vec2(warp_n, fbm(uv * 6.0 + 3.1)) - 0.5) * 0.0035 * pigment_bleed;
	vec2 suv = uv + warp;

	vec3 sharp = textureLod(screen_texture, suv, 0.0).rgb;
	// Multi-lobe soft blur (pigment diffusion)
	vec3 blur = vec3(0.0);
	float wsum = 0.0;
	vec2 offs[8] = vec2[](
		vec2(0.002, 0.0), vec2(-0.002, 0.0), vec2(0.0, 0.002), vec2(0.0, -0.002),
		vec2(0.0015, 0.0015), vec2(-0.0015, 0.0015), vec2(0.0015, -0.0015), vec2(-0.0015, -0.0015)
	);
	blur += textureLod(screen_texture, suv, 1.5).rgb * 0.35;
	wsum += 0.35;
	for (int i = 0; i < 8; i++) {
		blur += textureLod(screen_texture, suv + offs[i] * (1.0 + pigment_bleed), 2.2).rgb;
		wsum += 1.0;
	}
	blur /= wsum;

	// Prefer soft paint over hard pixels
	vec3 col = mix(blur, sharp, 0.38 + clarity * 0.35);

	// Chromatic pigment split (subtle — cover-print feel)
	float ch = 0.0012 * pigment_bleed;
	float cr = textureLod(screen_texture, suv + vec2(ch, 0.0), 1.0).r;
	float cb = textureLod(screen_texture, suv - vec2(ch, 0.0), 1.0).b;
	col.r = mix(col.r, cr, 0.22 * pigment_bleed);
	col.b = mix(col.b, cb, 0.22 * pigment_bleed);

	float lum = dot(col, vec3(0.299, 0.587, 0.114));

	// Soft bloom — amethyst + amber (movie poster glow, not neon)
	vec3 bloom = blur * smoothstep(bloom_threshold, 1.0, lum) * bloom_intensity;
	bloom *= vec3(1.05, 0.95, 1.12);
	bloom += vec3(0.72, 0.55, 0.95) * smoothstep(0.72, 1.0, lum) * bloom_intensity * 0.3;
	bloom += vec3(0.95, 0.78, 0.45) * smoothstep(0.8, 1.0, lum) * bloom_intensity * 0.15;
	col += bloom;

	// Watercolor wash: pull midtones toward muted Froud greens/violets
	vec3 wash_cool = vec3(0.42, 0.38, 0.55);
	vec3 wash_warm = vec3(0.72, 0.62, 0.48);
	vec3 wash = mix(wash_cool, wash_warm, smoothstep(0.25, 0.7, lum));
	col = mix(col, mix(col, wash, 0.35), wash_strength * 0.4);

	// Soft contrast (painted, not crunchy)
	col = (col - 0.5) * contrast + 0.5;
	float l2 = dot(col, vec3(0.299, 0.587, 0.114));
	// Slightly desaturated primaries (less "game UI bright")
	col = mix(vec3(l2), col, saturation);
	col *= tint.rgb;

	// Parchment lift in lights / amethyst in shadows (cover art lighting)
	col += vec3(gold_lift * 1.0, gold_lift * 0.78, gold_lift * 0.4) * smoothstep(0.25, 0.75, l2);
	col += vec3(0.04, 0.02, 0.08) * smoothstep(0.5, 0.05, l2);

	// Paper grain + fiber
	float grain = fbm(uv * vec2(920.0, 740.0));
	float fiber = fbm(uv * vec2(40.0, 180.0) + grain);
	col += (grain - 0.5) * paper_grain;
	col = mix(col, col * (0.96 + fiber * 0.08), paper_grain * 4.0);

	// Soft edge darkening like matted illustration
	vec2 v = uv * (1.0 - uv);
	float vig = pow(v.x * v.y * 11.0, 0.42);
	vec3 edge = vec3(0.18, 0.12, 0.22);
	col = mix(col * edge * 2.2, col, mix(0.72, 1.0, vig));

	// Final soft clamp into painterly range (avoid pure 0/1 game blacks)
	col = clamp(col, vec3(0.03), vec3(0.98));
	COLOR = vec4(col, 1.0);
}
