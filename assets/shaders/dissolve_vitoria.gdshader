shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 cell_count = vec2(42.0, 24.0);

// Gera o mosaico determinístico que faz o cenário desaparecer em fragmentos.
float cell_noise(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * cell_count);
	float threshold = cell_noise(cell);
	float wave = progress * 1.18;
	float coverage = smoothstep(threshold - 0.045, threshold + 0.045, wave);
	float rim = 1.0 - smoothstep(0.0, 0.09, abs(wave - threshold));
	float alpha = max(coverage, rim * 0.42 * (1.0 - coverage));
	COLOR = vec4(vec3(1.0), alpha);
}
