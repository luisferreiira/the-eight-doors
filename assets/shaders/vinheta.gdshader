shader_type canvas_item;
render_mode unshaded;

uniform float intensidade : hint_range(0.0, 0.8) = 0.40;
uniform float raio : hint_range(0.0, 1.0) = 0.32;
uniform float suavidade : hint_range(0.05, 1.0) = 0.58;

void fragment() {
	// Distancia eliptica em UV: independe do tamanho da janela e da camera.
	float distancia = length((UV - vec2(0.5)) * 2.0) / sqrt(2.0);
	float sombra = smoothstep(raio, raio + suavidade, distancia);
	COLOR = vec4(0.015, 0.012, 0.020, sombra * intensidade);
}
