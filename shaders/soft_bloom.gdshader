shader_type canvas_item;

// Soft ethereal grade: Dark Crystal light-flex (violet + teal + amber).
// Midtones stay clear so towers & monsters remain readable.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.62;
uniform float bloom_intensity : hint_range(0.0, 2.0) = 0.28;
uniform float saturation : hint_range(0.0, 2.0) = 1.08;
uniform float contrast : hint_range(0.5, 1.5) = 1.08;
uniform vec4 tint : source_color = vec4(1.0, 0.98, 1.04, 1.0);
uniform float gold_lift : hint_range(0.0, 0.2) = 0.03;
uniform float clarity : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec3 col = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	// Sharper base read (unsharp-ish mix with lod0) — keeps actors crisp
	vec3 sharp = col;
	vec3 blur = textureLod(screen_texture, SCREEN_UV, 2.0).rgb;
	blur += textureLod(screen_texture, SCREEN_UV + vec2(0.002, 0.0), 2.5).rgb;
	blur += textureLod(screen_texture, SCREEN_UV + vec2(-0.002, 0.0), 2.5).rgb;
	blur += textureLod(screen_texture, SCREEN_UV + vec2(0.0, 0.002), 2.5).rgb;
	blur += textureLod(screen_texture, SCREEN_UV + vec2(0.0, -0.002), 2.5).rgb;
	blur *= 0.2;

	// Local contrast restore so bloom doesn't haze gameplay
	col = mix(blur, sharp, 0.72 + clarity * 0.25);

	float lum = dot(blur, vec3(0.299, 0.587, 0.114));
	// Amethyst + teal bloom on bright areas (crystal / essence)
	vec3 bloom_col = mix(blur, blur * vec3(0.95, 0.92, 1.08), 0.55);
	vec3 bloom = bloom_col * smoothstep(bloom_threshold, 1.0, lum) * bloom_intensity;
	// Soft violet highlight spill + river-green edge
	bloom += vec3(0.78, 0.62, 1.0) * smoothstep(0.75, 1.0, lum) * bloom_intensity * 0.28;
	bloom += vec3(0.55, 0.85, 0.78) * smoothstep(0.82, 1.0, lum) * bloom_intensity * 0.12;
	col += bloom;

	// Contrast + gentle saturation
	col = (col - 0.5) * contrast + 0.5;
	float l2 = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l2), col, saturation);
	col *= tint.rgb;

	// Soft amber light-flex in midtones (Froud fairy-tale warmth — subtle)
	col += vec3(gold_lift * 0.95, gold_lift * 0.72, gold_lift * 0.45) * (1.0 - abs(l2 - 0.5) * 1.5);
	// Cool violet lift in shadows
	col += vec3(0.02, 0.01, 0.04) * smoothstep(0.45, 0.05, l2);

	// Mild vignette (deep violet edge, not black)
	vec2 v = SCREEN_UV * (1.0 - SCREEN_UV);
	float vig = pow(v.x * v.y * 14.0, 0.38);
	col = mix(col * vec3(0.88, 0.82, 0.96), col, mix(0.8, 1.0, vig));

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
