shader_type canvas_item;

// A animação avança pelo AnimationPlayer: pausa junto com a partida.
uniform float fase = 0.0;
uniform float amplitude : hint_range(0.0, 3.0) = 1.4;
varying vec4 modulacao;

void vertex() {
	modulacao = COLOR;
}

// Deforma somente a chama do recorte original, mantendo o suporte imóvel.
void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	vec2 local = pixel - vec2(944.0, 0.0);
	float fogo = 1.0 - smoothstep(22.0, 37.0, local.y);
	float passo = floor(fase * 4.0) / 4.0;
	vec2 deslocamento = vec2(sin(passo * 2.0 + local.y * 0.16), sin(passo * 3.0)) * amplitude * fogo;
	vec2 amostra = local + round(deslocamento);
	vec4 cor = texture(TEXTURE, (vec2(944.0, 0.0) + amostra) * TEXTURE_PIXEL_SIZE);
	if (amostra.x < 0.0 || amostra.x >= 32.0 || amostra.y < 0.0 || amostra.y >= 80.0) {
		cor = vec4(0.0);
	}
	cor.rgb *= 1.0 + fogo * 0.06 * sin(passo * 3.0);
	COLOR = cor * modulacao;
}
