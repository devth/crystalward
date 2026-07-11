shader_type canvas_item;

// Warm dirt path with soft edges — readable lanes.
uniform vec4 dirt_dark : source_color = vec4(0.35, 0.25, 0.18, 0.95);
uniform vec4 dirt_lit : source_color = vec4(0.55, 0.42, 0.28, 0.9);
uniform vec4 edge_glow : source_color = vec4(0.75, 0.55, 0.9, 0.35);
uniform float pulse_speed : hint_range(0.1, 4.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float edge = abs(UV.x - 0.5) * 2.0;
	float center = 1.0 - smoothstep(0.05, 0.98, edge);
	float grit = hash(floor(UV * vec2(40.0, 80.0)));
	vec3 dirt = mix(dirt_dark.rgb, dirt_lit.rgb, grit);
	float vein = 0.5 + 0.5 * sin(UV.y * 30.0 - TIME * pulse_speed * 2.0);
	dirt = mix(dirt, edge_glow.rgb, (1.0 - edge) * 0.2 * vein);

	float a = dirt_dark.a * center;
	// Soft feather
	a *= smoothstep(1.0, 0.55, edge);
	COLOR = vec4(dirt, a);
}
