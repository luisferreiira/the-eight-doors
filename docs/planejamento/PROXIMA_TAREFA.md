# Próxima tarefa recomendada

**Implementar uma fatia vertical de primeiro enigma: interação E → conclusão persistente durante a partida → uma porta condicionada.** Não executada nesta auditoria. Antes de começar, concluir a verificação visual pontual da prévia do editor descrita no estado atual e escolher uma regra simples para o enigma.

## Por que agora

A navegação básica já existe; o maior vazio é o ciclo de resolução e progresso. Uma única entrega pequena permite validar o contrato de estados antes de criar dezenas de salas. Não exige novas artes nem refinamento das animações pausadas.

## Escopo proposto para a próxima sessão

- Definir um único enigma simples de sequência de símbolos, com regra e feedback aprovados antes da implementação; sem inventário.
- Criar ação E e detecção de interação próxima, recusando interação durante pausa e transição.
- Registrar conclusão por ID em estado da partida e definir reset de nova partida/reinício/retorno ao menu.
- Condicionar uma conexão existente à conclusão, mantendo destino, reciprocidade e entrada oposta do mapa. Separar conexão existente bloqueada de direção sem conexão.
- Restaurar visual/colisão da porta ao revisitar a sala. Emitir conclusão apenas uma vez; preparar evento para pontuação futura, sem criar todo o sistema de pontos.

## Arquivos prováveis

- `project.godot`: ação de interação.
- `scripts/autoload/estado_jogo.gd`: acesso ao progresso ou ligação a um estado de partida separado; evitar concentrar regras de enigmas e áudio no mesmo objeto.
- Novos scripts de interação/enigma e estado, com responsabilidade explícita.
- `scripts/world/porta.gd`, `sala.gd` e configuração da sala escolhida: condição e aplicação do desbloqueio.
- `scenes/world/rooms/sala_s01.tscn` (candidata, confirmar no início): objeto interativo, sem regenerar a sala-base.
- `scripts/autoload/pause_overlay.gd` e início de partida: somente se necessário ao reset definido.
- Novos testes direcionados e documentos de planejamento. Alterar `mapa.gd`/catálogo apenas se a configuração exigir, preservando as coordenadas existentes.

## Aceite e validação

Com Aelin e Dorian: E fora de alcance não atua; próximo mostra feedback; sequência incorreta não conclui; correta registra uma vez e abre a porta; saída/reentrada conserva a conclusão; pausa e fade não permitem interagir; reinício e nova partida obedecem ao reset. Rodar novamente `test_labirinto.gd` e `test_integracao_menus.gd`; se a porta do cenário de teste mudar de estado inicial, definir fixtures explícitas e manter a cobertura original, sem simplesmente remover as verificações que falharem.

Preservar personagens, animações, assets, câmera, seis coordenadas, transições automáticas, fade nominal de dois segundos, proteção de retorno, mapa do editor e fluxo de seleção/pausa. Ficam fora desta entrega: vidas, diário, mapa do jogador, expansão, novas saídas e vitória.
