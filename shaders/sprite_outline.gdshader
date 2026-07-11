shader_type canvas_item;

// Soft pixel outline for PJ Monsters–style readability.
uniform vec4 outline_color : source_color = vec4(0.08, 0.05, 0.12, 0.95);
uniform float outline_width : hint_range(0.0, 4.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;

	float a = col.a;
	float max_a = a;
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);

	if (a < 0.1 && max_a > 0.1) {
		COLOR = outline_color;
	} else {
		// Slight lift for punchier colors
		col.rgb = mix(col.rgb, col.rgb * 1.08 + vec3(0.02), 0.35);
		COLOR = col;
	}
}
