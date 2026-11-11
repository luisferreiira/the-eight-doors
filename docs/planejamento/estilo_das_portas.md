# Portas especiais — sobreposições editáveis

Atualização de gameplay: E0 (S01 ↔ S04) já possui o [primeiro desafio](primeiro_desafio.md), com interação por E e abertura persistente durante a partida. Os demais atalhos continuam reservados.

As peças reutilizam os recortes originais dos atlas. A cor é aplicada por materiais da Godot, preservando pixels, transparência, relevo e sombras. Não há cópias recoloridas dos PNGs nem novos selos ou runas.

- **Dourado:** saídas da S14/oeste e S21/norte.
- **Vinho:** as duas faces das oito conexões fechadas E0 e D3–D9. Os desafios ainda não foram implementados.
- **Arte original:** portas comuns, abertas ou sem conexão.

## Onde visualizar e editar

Abra `scenes/world/doors/catalogo_portas.tscn` na aba 2D. A primeira linha mostra as oito direções em dourado; a segunda, em vinho.

As cenas em `scenes/world/doors/visuais/porta_*.tscn` têm origem no centro da porta lógica. Cada cena contém `Moldura` e `Grade`; as laterais também contêm `BasePedra`. Os recortes, posições, escalas e materiais ficam persistidos na cena e podem ser editados no Inspector. Os modelos norte/sul e as diagonais mantêm os recortes da sala-base; as laterais reaproveitam seu batente estreito e a pedra inferior.

As paletas estão em `assets/materials/doors/ouro.tres` e `vinho.tres`. Abra o material e ajuste **Shader Parameters → Tonalidade, Ganho ou Mistura**. Como o material é compartilhado, a alteração aparece em todas as portas que o usam. Use **Make Unique / Tornar único** para mudar apenas uma instância.

## Como a sobreposição está aplicada

Nas cenas individuais das salas, cada porta especial contém `Passagens/Porta_<direção>/VisualEspecial`. Esse nó instancia o visual da direção correspondente. O material fica no nó raiz e seus sprites usam o material do pai.

A `GradeFechada` original permanece como referência, com **Self Modulate → alpha = 0**, evitando duplicar a imagem. Sua colisão e o comportamento da porta continuam nos nós existentes. `porta.gd` sincroniza a visibilidade da grade da sobreposição com o estado aberto/fechado. A sobreposição não cria outro `Area2D`, colisão ou transição.

Para aplicar uma sobreposição em outra sala: instancie o modelo da direção correta como `VisualEspecial`, filho da porta correspondente, com posição `(0, 0)`; escolha o material e deixe transparente a grade original. Para uma porta inicialmente aberta, salve também `VisualEspecial/Grade.visible = false` na cena, garantindo uma prévia fiel no editor.

## Identificação da saída

`saida.tscn` agora contém apenas a placa e o marcador de interação. O antigo `Arco` em `Line2D` e o texto solto foram removidos. A placa reutiliza a textura de moldura de pedra existente e é editável em `placa_saida.tscn`.

`saida_norte.tscn` prende a placa à parte superior da grade. `saida_oeste.tscn` a orienta verticalmente sobre a grade lateral. O marcador `Interacao` conserva sua posição anterior; a vitória continua sendo acionada por **E**.

Verificação: catálogo e seis enquadramentos no jogo renderizados sem erros. A regressão do labirinto passou com 16 travessias, 150 bloqueios, 6.000 verificações do contorno e vitória nas duas saídas. A prévia do catálogo está em `docs/planejamento/catalogo_portas.png`.
