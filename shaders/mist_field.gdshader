shader_type canvas_item;

// Painted mist washes — soft amethyst + teal pigment
uniform vec4 mist_a : source_color = vec4(0.48, 0.36, 0.62, 0.28);
uniform vec4 mist_b : source_color = vec4(0.36, 0.52, 0.50, 0.18);
uniform float speed : hint_range(0.1, 3.0) = 0.6;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	vec2 uv = UV;
	vec2 c = uv - 0.5;
	float r = length(c);
	float falloff = smoothstep(0.5, 0.1, r);

	float n = noise(uv * 4.0 + vec2(TIME * speed, TIME * speed * -0.4));
	n += 0.5 * noise(uv * 8.0 - vec2(TIME * speed * 0.7, 0.0));
	n *= 0.65;

	vec3 col = mix(mist_a.rgb, mist_b.rgb, n);
	float a = falloff * mix(mist_a.a, mist_b.a, n) * (0.55 + 0.45 * n);
	COLOR = vec4(col, a);
}
