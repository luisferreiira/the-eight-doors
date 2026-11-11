# Salas e conexões implementadas — 2026-11-09

Atualização de 2026-11-10: novas partidas agora sorteiam S22, S23 ou S29. Consulte [distribuição dos nascimentos](nascimentos.md). O início fixo na S01 descrito nesta entrega original permanece disponível somente como opção de teste.

O esboço aprovado foi aplicado ao jogo: **30 salas, 45 conexões abertas e 8 fechadas**. Cada conexão funciona nos dois sentidos, com chegada pela porta oposta e o fade já existente. Todas as salas são alcançáveis pela rede aberta.

## O que está disponível

- S01–S30 têm cenas individuais em `scenes/world/rooms/sala_sXX.tscn`, herdadas da sala octogonal existente. A decoração base é compartilhada; cada sala tem os nós `ConteudoDaSala/Decoracao`, `Obstaculos` e `Interacoes` para personalização futura.
- As grades e colisões das passagens já aparecem abertas ou fechadas no editor 2D, conforme o mapa. `mapa.gd` define destinos e bloqueios; `cenas_salas.gd` registra as cenas carregadas pelo jogo.
- A saída A ocupa a porta **oeste da S14**. A saída B ocupa a porta **norte da S21**. Ambas têm grade dourada, legenda e marcador de interação. Aproximar-se e pressionar **E** abre a vitória existente. A antiga saída sul da S04 foi retirada.
- As oito ligações fechadas têm destino cadastrado, mas a grade impede a travessia nas duas faces. Ainda não há interação para abri-las. Portas sem ligação também continuam fechadas.

Atualização visual: as saídas agora usam sobreposições douradas e uma placa presa à grade; as duas faces dos oito atalhos usam sobreposições roxas. O arco de linha e o texto solto foram removidos. Veja [estilo das portas](estilo_das_portas.md) e a cena `scenes/world/doors/catalogo_portas.tscn`.

| Identificador reservado | Conexão fechada |
|---|---|
| E0 | S01 ↔ S04 |
| D3 | S23 ↔ S26 |
| D4 | S06 ↔ S30 |
| D5 | S07 ↔ S09 |
| D6 | S02 ↔ S16 |
| D7 | S03 ↔ S17 |
| D8 | S04 ↔ S26 |
| D9 | S25 ↔ S27 |

## Como editar e testar

1. Abra `scenes/world/labyrinth/mapa_editor.tscn` na aba **2D** para ver as 30 salas e 53 conexões. Guias ciano indicam conexões abertas; guias laranja indicam conexões fechadas. São guias de planejamento, não corredores físicos.
2. Abra a cena individual `sala_sXX.tscn` para editar a sala usada no jogo. Alterações feitas somente na instância da visão geral não são propagadas à cena de origem. Os nós herdados podem ser ajustados no Inspector; novos objetos ficam em `ConteudoDaSala`.
3. As sinalizações são cenas próprias: `scenes/world/doors/saida_oeste.tscn` e `saida_norte.tscn`. O marcador `Interacao` controla a posição usada para detectar proximidade.
4. Execute `scenes/world/labyrinth/labirinto.tscn` com **F6**, ou o projeto com **F5**. A partida continua iniciando na S01.

A visão geral tem instâncias, rótulos e guias persistidos na `.tscn`; o botão **Validar mapa** apenas verifica os dados e as posições. Não recria nem apaga ajustes visuais. Ao mudar a topologia no futuro, atualize também as prévias das salas e as guias da visão geral.

## Etapas ainda reservadas

Não foram implementados os efeitos de sala, os três novos pontos de nascimento, as dicas estratégicas ou os novos desafios. O enigma E0 do protótipo deixou de ser acionado e a dica antiga da S01 foi desativada. As cenas e os ajustes de posicionamento das runas antigas foram preservados, mas suas instâncias estão ocultas na sala-base para a futura estilização.

## Verificação

`tests/test_labirinto.gd` cobre contagem e reciprocidade das conexões, bloqueios simétricos, acesso às 30 salas, distâncias aprovadas até as saídas, prévias persistidas, colisões, limites da câmera, travessias com Aelin e Dorian e vitória nas duas saídas. O relatório da execução fica em `.godot/testes_expansao.json`.

Execução concluída sem falhas: 16 travessias físicas, 150 portas fechadas verificadas, 6.000 varreduras de contorno e vitória nas duas saídas. `tests/test_integracao_menus.gd` também passou nos 97 checks com Aelin e Dorian. As saídas e a visão geral foram renderizadas para conferência visual.
