shader_type canvas_item;

// Soft ink wash outline — hand-drawn cover art, not hard arcade neon.
uniform vec4 outline_color : source_color = vec4(0.14, 0.09, 0.18, 0.72);
uniform float outline_width : hint_range(0.0, 4.0) = 1.15;
uniform float wash : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;

	float a = col.a;
	float max_a = a;
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	// Softer diagonal sample for brushy edge
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, px.y) * 0.7).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, -px.y) * 0.7).a);

	if (a < 0.12 && max_a > 0.12) {
		// Semi-transparent ink so it feels painted on, not a hard game stroke
		vec4 ink = outline_color;
		ink.a *= smoothstep(0.12, 0.55, max_a) * 0.85;
		COLOR = ink;
	} else {
		// Slight desat + warm lift — less plastic pixel punch
		float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		col.rgb = mix(vec3(lum), col.rgb, 0.88);
		col.rgb = mix(col.rgb, col.rgb * vec3(1.04, 1.0, 1.06) + vec3(0.015), wash * 0.5);
		COLOR = col;
	}
}
