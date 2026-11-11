shader_type canvas_item;

// Recolore as peças originais preservando alpha, sombras e detalhes do pixel art.
uniform vec4 tonalidade : source_color = vec4(0.72, 0.42, 1.0, 1.0);
uniform float ganho : hint_range(0.0, 3.0) = 1.9;
uniform float mistura : hint_range(0.0, 1.0) = 0.9;

// Conserva modulação do nó sem multiplicar a textura duas vezes no fragmento.
varying vec4 modulacao;
void vertex() {
	modulacao = COLOR;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float luminosidade = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	vec3 tingido = luminosidade * tonalidade.rgb * ganho;
	COLOR = vec4(mix(original.rgb, tingido, mistura), original.a) * modulacao;
}
