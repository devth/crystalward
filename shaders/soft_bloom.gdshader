shader_type canvas_item;

// Cheap fullscreen bloom/lift for “finished game” glow.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.55;
uniform float bloom_intensity : hint_range(0.0, 2.0) = 0.45;
uniform float saturation : hint_range(0.0, 2.0) = 1.15;
uniform float contrast : hint_range(0.5, 1.5) = 1.06;
uniform vec4 tint : source_color = vec4(1.0, 0.98, 1.04, 1.0);

void fragment() {
	vec3 col = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 blur = textureLod(screen_texture, SCREEN_UV, 2.0).rgb;
	blur += textureLod(screen_texture, SCREEN_UV + vec2(0.002, 0.0), 2.5).rgb;
	blur += textureLod(screen_texture, SCREEN_UV + vec2(-0.002, 0.0), 2.5).rgb;
	blur += textureLod(screen_texture, SCREEN_UV + vec2(0.0, 0.002), 2.5).rgb;
	blur += textureLod(screen_texture, SCREEN_UV + vec2(0.0, -0.002), 2.5).rgb;
	blur *= 0.2;

	float lum = dot(blur, vec3(0.299, 0.587, 0.114));
	vec3 bloom = blur * smoothstep(bloom_threshold, 1.0, lum) * bloom_intensity;
	col += bloom;

	// Contrast + saturation
	col = (col - 0.5) * contrast + 0.5;
	float l2 = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l2), col, saturation);
	col *= tint.rgb;

	// Soft vignette
	vec2 v = SCREEN_UV * (1.0 - SCREEN_UV);
	float vig = pow(v.x * v.y * 14.0, 0.35);
	col *= mix(0.75, 1.0, vig);

	COLOR = vec4(col, 1.0);
}
