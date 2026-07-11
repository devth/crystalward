shader_type canvas_item;

uniform vec4 color_core : source_color = vec4(0.85, 0.75, 1.0, 1.0);
uniform vec4 color_edge : source_color = vec4(0.25, 0.55, 0.45, 1.0);
uniform vec4 color_glow : source_color = vec4(0.55, 0.35, 0.85, 0.55);
uniform float shimmer_speed : hint_range(0.1, 4.0) = 1.4;
uniform float facet_scale : hint_range(1.0, 20.0) = 7.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * shimmer_speed;

	// Soft radial crystal body
	vec2 c = uv - vec2(0.5);
	float r = length(c * vec2(1.0, 1.15));
	float body = smoothstep(0.52, 0.18, r);

	// Facet-like bands
	float bands = sin((uv.x * 3.1 + uv.y * 5.4) * facet_scale + t * 0.7);
	bands = bands * 0.5 + 0.5;
	float spark = pow(hash(floor(uv * 28.0 + t * 0.2)), 12.0);

	// Vertical light shaft
	float shaft = exp(-abs(c.x) * 9.0) * smoothstep(0.7, 0.1, uv.y) * (0.45 + 0.55 * sin(t * 1.7));

	vec3 col = mix(color_edge.rgb, color_core.rgb, bands * 0.55 + shaft * 0.35);
	col += color_glow.rgb * shaft * 0.8;
	col += vec3(0.9, 1.0, 0.95) * spark * 0.65;
	col += color_glow.rgb * (0.15 + pulse * 0.25 * sin(t * 2.2));

	float alpha = body * color_core.a;
	alpha *= 0.75 + 0.25 * bands;
	COLOR = vec4(col, alpha);
}
