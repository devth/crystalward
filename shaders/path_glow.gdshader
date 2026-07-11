shader_type canvas_item;

uniform vec4 path_color : source_color = vec4(0.22, 0.12, 0.28, 0.85);
uniform vec4 edge_glow : source_color = vec4(0.55, 0.35, 0.75, 0.4);
uniform float pulse_speed : hint_range(0.1, 4.0) = 1.2;

void fragment() {
	float t = TIME * pulse_speed;
	// UV.x across path width, UV.y along path — soft center channel
	float edge = abs(UV.x - 0.5) * 2.0;
	float center = 1.0 - smoothstep(0.15, 0.95, edge);
	float vein = 0.5 + 0.5 * sin(UV.y * 40.0 - t * 2.0);
	vec3 col = mix(path_color.rgb, edge_glow.rgb, (1.0 - edge) * 0.45 * vein);
	float a = path_color.a * center * (0.75 + 0.25 * vein);
	COLOR = vec4(col, a);
}
