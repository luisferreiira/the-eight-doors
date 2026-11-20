shader_type canvas_item;

// Preserva a borda e os losangos da arte original, cobrindo apenas o símbolo central.
uniform vec4 area_central = vec4(0.24, 0.22, 0.76, 0.79);
uniform float coluna_pedra = 0.23;
// Alfa zero mantém a textura original. Alfa um aplica um preenchimento uniforme.
uniform vec4 cor_centro : source_color = vec4(0.0);

void fragment() {
	vec2 inicio = smoothstep(area_central.xy, area_central.xy + vec2(0.012), UV);
	vec2 fim = 1.0 - smoothstep(area_central.zw - vec2(0.012), area_central.zw, UV);
	float mascara = inicio.x * inicio.y * fim.x * fim.y;
	vec4 pedra = texture(TEXTURE, vec2(coluna_pedra, UV.y));
	pedra.rgb = mix(pedra.rgb, cor_centro.rgb, cor_centro.a);
	COLOR = mix(COLOR, pedra, mascara);
}
