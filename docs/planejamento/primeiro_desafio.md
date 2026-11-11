# Primeiro desafio — S01 ↔ S04

A porta vinho E0 pode ser examinada com **E**, perto do marcador interno de qualquer uma das duas faces. O painel de pedra apresenta o enigma **O ciclo da luz**, com detalhes vinho e uma inscrição rimada. A sequência é **Estrela → Lua → Sol**.

- Escolher três pedras habilita **Confirmar**; **Limpar** reinicia a seleção.
- Uma resposta incorreta limpa a sequência e permite tentar novamente.
- **Fechar** ou **Esc** devolve o controle sem alterar a porta.
- A resposta correta fecha o painel e anima a grade por 0,65 s. Movimento e pausa ficam bloqueados até terminar; só então a colisão é liberada.
- A passagem permanece aberta nos dois sentidos, inclusive após visitar outras salas. Reiniciar a partida limpa o progresso.
- Os outros sete atalhos continuam fechados. Pontuação e perda de vida ficam para a etapa seguinte.

## Edição

O painel continua em `scenes/ui/gameplay/painel_selo.tscn`, editável no 2D. Layout, textos, estilos e botões estão persistidos na cena. A solução é definida em `STONE_SOLUTION`, no controlador `scripts/world/labirinto.gd`; ao mudar o enigma, mantenha texto e solução coerentes.

As propriedades **Opening Duration** e **Opening Height** das portas permitem ajustar a abertura no Inspector. O movimento usa a posição já definida para a grade da sobreposição e não desloca a moldura. Os comentários dos blocos alterados explicam interação, progresso e animação.

`tests/test_primeiro_desafio.gd` verifica alcance, cancelamento, resposta incorreta, solução, colisão durante a abertura, travessia, retorno, nova partida e resolução pela face oposta.
