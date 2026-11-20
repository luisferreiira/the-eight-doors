shader_type canvas_item;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 origem = vec2(0.5);

// A frente luminosa parte do vão real e alcança até o canto mais distante.
void fragment() {
	vec2 proporcao = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float distancia = length((UV - origem) * proporcao);
	float alcance = length(max(abs(origem), abs(vec2(1.0) - origem)) * proporcao);
	float frente = mix(-0.10, alcance + 0.10, progress);
	float preenchimento = 1.0 - smoothstep(frente - 0.075, frente + 0.075, distancia);
	float eco = 1.0 - smoothstep(0.0, 0.024, abs(distancia - frente - 0.055));
	COLOR = vec4(vec3(1.0), max(preenchimento, eco * 0.55));
}
