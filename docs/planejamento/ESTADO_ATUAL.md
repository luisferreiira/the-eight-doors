# Auditoria do estado atual

Data: **04/11/2026**. Base auditada: commit **8db3d7b**, branch `main`. Somente documentação e evidências foram criadas nesta tarefa; nenhuma mecânica, cena, arte, configuração do projeto ou teste foi alterado.

## Resumo técnico

O projeto é um **protótipo de exploração funcional**, ainda sem ciclo de resolução e conclusão de partida. F5 abre `scenes/ui/menus/MenuInicial.tscn`, não o labirinto histórico. Play → `EscolhaPersonagem.tscn` → Next → `scenes/world/labyrinth/labirinto.tscn`.

`docs/expansao_2026-10-30/README.md` não existe no caminho solicitado: o documento foi movido para `docs/history/expansao_2026-10-30/README.md`. Foi lido junto de `docs/arquitetura_codigo.md`, `docs/estrutura_projeto.md` e `docs/history/integracao_menus_2026-11-03/README.md`. Há referências históricas desatualizadas nessas fontes: caminhos antigos, ausência de Git e afirmações de cena principal anterior. Código e cenas atuais prevalecem; os históricos foram preservados.

## Arquitetura efetiva

| Responsabilidade | Arquivos atuais e comportamento |
|---|---|
| Configuração | `project.godot`: Godot 4.7, GL Compatibility, viewport gameplay 640×360, janela 1280×720; os menus ajustam o tamanho lógico para 1280×720 |
| Inicialização e seleção | `scenes/ui/menus/{MenuInicial,EscolhaPersonagem}.tscn`; `scripts/ui/{menu_inicial,escolha_personagem}.gd` |
| Estado e áudio | Autoload `EstadoJogo` → `scripts/autoload/estado_jogo.gd`: personagem escolhido, cena de gameplay, música, som de botão e volume; não contém progresso de enigmas |
| Pausa | Autoload `PauseOverlay` → `scripts/autoload/pause_overlay.gd`: Esc, retomar, reiniciar, volume e menu; impede pausa durante travessia |
| Orquestração | `scripts/world/labirinto.gd`: valida mapa/catálogo, instancia jogador, conserva jogador/câmera, substitui apenas a sala visual e coordena fade |
| Mapa | `scripts/world/mapa.gd`: coordenadas, oito direções/opostas, ligações explícitas, spawn seguro e validação geométrica |
| Cenas por sala | `scripts/world/cenas_salas.gd` cataloga `scenes/world/rooms/sala_s01.tscn` até `sala_s06.tscn`; herdam `scenes/world/labyrinth/sala_octogonal_base.tscn`; têm nós de conteúdo, decoração, obstáculos e interações, ainda sem sistema de enigmas |
| Sala/porta | `scripts/world/{sala,porta}.gd`: posicionamento físico, ordenação Y, colisões, oito áreas de porta, grades/selos, destino e marcador de entrada |
| Personagens | `scenes/characters/players/{aelin,dorian}.tscn`; `scripts/characters/personagem_top_down.gd`: CharacterBody2D, velocidade padrão 144, Input.get_vector, colisões e AnimatedSprite2D; idle de Aelin usa `parada`, Dorian `parado` |
| Câmera | `scripts/camera/camera_exploracao.gd`: zoom 1, posição local (0,-24), sem suavização; limites atualizados pelo labirinto |
| Fade/atmosfera | `scripts/effects/transicao_fade.gd`: CanvasLayer 100, 0,8/0,4/0,8 s; `scenes/world/environments/atmosfera.tscn` e `assets/shaders/vinheta.gdshader`: vinheta na camada 10; HUD 11 e pausa 80 |
| Editor | `scenes/world/labyrinth/mapa_editor.tscn` e `tools/editor/mapa_editor.gd`: prévia @tool com catálogo compartilhado, IDs e linhas; gerada apenas em modo editor |
| Recursos | TileSet em `resources/generated/dungeon_central/sala_central_tileset.tres`; artes em `assets/characters`, `environments`, `ui`; áudio em `assets/audio/music` e `sfx`; nenhuma regeneração de assets feita |
| Infraestrutura | Autoloads `MCPRuntime` (`addons/godot_mcp/runtime/mcp_runtime.gd`) e `_mcp_game_helper` (`addons/godot_ai/runtime/game_helper.gd`). Plugin de editor habilitado: Godot AI 4.3.1. `ziva_agent` existe, mas não está habilitado no project.godot |

Não há dependência funcional demonstrada do backend MCP para jogar: os testes rodaram com `debugger active=false`. Os autoloads ainda estão referenciados, portanto remover suas pastas sem ajustar o projeto quebraria referências. Não foi validada a exclusão dessas ferramentas na exportação.

## Mapa confirmado

| Sala | Coordenada | Conexões |
|---|---|---|
| S01 | (0,0) | N→S02; NE→S03; L→S04; S→S05; SO→S06 |
| S02 | (0,-1) | S→S01 |
| S03 | (1,-1) | SO→S01 |
| S04 | (1,0) | O→S01 |
| S05 | (0,1) | N→S01 |
| S06 | (-1,1) | NE→S01 |

São cinco arestas bidirecionais e dez portas abertas entre 48 posições; 38 seladas. Grau médio 1,67, portanto o protótipo ainda não representa a intenção de aproximadamente cinco conexões por sala. Passo físico (1440,1216); corredores externos são implícitos na troca, não navegáveis. O validador exige destino existente, direção correta, retorno, coordenadas únicas, ausência de sobreposição e de cruzamentos geométricos. Exceções unidirecionais não são suportadas atualmente.

## Inventário de funcionalidades

Legenda: **CT** = CONCLUÍDA E TESTADA no escopo descrito; **IT** = IMPLEMENTADA, MAS NÃO TESTADA nesta auditoria; **PI** = PARCIALMENTE IMPLEMENTADA; **NI** = NÃO IMPLEMENTADA; **BD** = BLOQUEADA POR DEPENDÊNCIA; **ND** = AINDA NÃO DEFINIDA NO DESIGN. Teste funcional headless não certifica acabamento visual ou versão final.

| Sistema | Estado | Evidência e arquivos responsáveis | Pendência | Prioridade |
|---|---|---|---|---|
| Tela inicial e escolha | CT | Scripts UI, cenas de menus, EstadoJogo; 97 checks de integração incluindo ambos personagens | Revisão visual futura em build exportada | P1, manter |
| Movimentação | CT | personagem_top_down.gd; oito direções/normalização e colisões em test_labirinto.gd | Nenhum bloqueio funcional encontrado | P1, manter |
| Animações | PI | AnimatedSprite2D nas cenas de ambos; seleção de corrida/idle no controlador | Refinamento visual solicitado está pausado; testes não certificam qualidade artística | P3 |
| Câmera | CT | camera_exploracao.gd e limites em labirinto.gd; verificações da bateria | Testar restauração quando houver efeitos | P1, manter |
| Sala-base e seis salas | CT | Base octogonal + catálogo + seis cenas herdadas; travessias/perímetro | Conteúdo individual ainda limitado | P2 |
| Mapa espacial | CT | mapa.gd; cinco casos inválidos rejeitados | Validar cada expansão; exceções direcionais exigem design e adaptação | P1, manter |
| Portas abertas/seladas | CT para estado estático | porta.gd abre quando destino não vazio; teste de 38 bloqueios | Condições de progresso não existem; não confundir porta selada sem destino com porta conectada bloqueada | P1 |
| Transições automáticas | CT | labirinto.gd e porta.gd; 20 travessias, chegada oposta, personagem persistente e trava de retorno | Revalidar após introduzir estados | P1, manter |
| Fade de dois segundos | CT | transicao_fade.gd: 0,8 + 0,4 + 0,8; teste mede duração, bloqueio do movimento e preto na troca | Tempo nominal não inclui pausas externas/carregamento; não é apenas documentação | P1, manter |
| Mapa completo no editor | IT nesta sessão | mapa_editor.gd instancia catálogo, seis IDs e cinco guias; há evidência MCP histórica de validação | Não foi aberto visualmente nesta auditoria; conferir preview após expansão | P2 |
| Spawn aleatório | PI | random_spawn=false por padrão; sorteio implementado, todas as seis salas safe=true; semente 42 testada → S06 | Habilitar no fluxo pretendido após validar equilíbrio; não há avaliação de rotas/requisitos | P1 |
| Enigmas | NI | Nenhum controlador de enigma no gameplay; nós Interacoes são estrutura, não mecânica | Regra inicial + componente reutilizável | P1 |
| Interação E | NI | Input Map só contém movimento personalizado; ausência de sistema no controlador | Ação, alcance, alvo e feedback | P1 |
| Progresso da partida | NI | EstadoJogo guarda seleção/áudio, não pistas/enigmas | IDs, eventos, persistência entre salas e reset | P1 |
| Portas condicionadas | BD | Porta depende apenas de destino não vazio | Depende de progresso e contrato de condição; grafo deve manter conexão | P1 |
| Efeitos mágicos temporários | NI | Câmera e vinheta estáticas não implementam os efeitos propostos | Componentes, entrada/saída e restauração | P2 |
| Diário | NI | Sem modelo/UI de pistas | Depende de eventos de descoberta e IDs | P2 |
| Mapa do jogador | NI | Só há ferramenta @tool de editor | Imagem/interface sem marcador de posição | P2 |
| Vidas e perda de vida | NI; regras ND | Não há estado de vidas/dano no gameplay | Três vidas definidas; causas de dano, proteção e reset ainda abertos | P1 para versão completa |
| Pontuação | NI | Sem saldo/eventos de recompensa | Valores propostos; registrar recompensa uma vez por ID | P1 para versão completa |
| Múltiplas saídas | NI; requisitos ND | Seis salas só têm conexões internas | Quantidade, requisitos, rotas e visual | P2; uma saída P1 |
| Vitória e tela de conclusão | BD | Sem avaliador de saída/objetivos ou cena final | Depende de enigma, progresso e saída válida | P1 |
| Tela de derrota | BD; regra ND | Ausente | Depende de vidas/dano e regra de fim de partida | P1 para versão completa |
| Interface | PI | Label de sala/personagem/WASD, menus, pausa e volume | HUD de vidas/pontos, diário/mapa e resultados | P1/P2 |
| Áudio | PI | EstadoJogo toca música e botão; volume validado por integração | Passos/portas/mecanismos/magia e revisão sonora | P2/P3 |
| Exportação | NI no repositório auditado | Sem export_presets.cfg ou build validada; plugin tem código de exportação, o que não comprova export do jogo | Escolher plataforma, templates, preset e smoke test fora do editor | P1 validar cedo; P2 entrega |

## Validação executada em 04/11/2026

Executável: `C:/Users/luisg/Downloads/apps/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.

1. Auditoria estática de referências literais de recurso em project.godot, scenes, scripts e resources: **87 ocorrências verificadas, nenhuma ausente**. Evidência: [referencias.json](evidencias/referencias.json). Não cobre strings dinâmicas, caminhos em ferramentas/históricos ou todos os internos dos addons.
2. `--headless --path . --script res://tests/test_labirinto.gd`: **exit 0**, 20 travessias com Aelin/Dorian, 38 portas seladas, 1.200 varreduras, cinco mapas inválidos rejeitados, spawn semeado em S06 e zero falhas. Evidências: [labirinto.json](evidencias/labirinto.json), [labirinto.log](evidencias/labirinto.log). Inclui câmera, WASD, entradas seguras e fade: as 20 medições ficaram entre **1,932 e 2,069 segundos**, dentro da tolerância do teste (1,9–2,4 s).
3. `--headless --path . --script res://tests/test_integracao_menus.gd`: **exit 0**, **97 verificações, zero falhas**, ambos personagens, seleção, pausa, reinício, volume, travessia e resoluções. Evidências: [menus.json](evidencias/menus.json), [menus.log](evidencias/menus.log).
4. O log de integração contém ao encerrar **2 instâncias ObjectDB vazadas** e **1 recurso ainda em uso**. Não invalida as verificações funcionais, mas impede afirmar que o encerramento está limpo. Origem não determinada: pode estar no teste, infraestrutura ou projeto. Diagnosticar com execução verbose direcionada antes da distribuição; não refatorar com base em hipótese.

As primeiras tentativas no sandbox encerraram por access violation/signal 11 antes da bateria. Repetição fora do sandbox concluiu ambos os testes; não há evidência de que o crash inicial seja falha do gameplay. Relatórios históricos sobrescritos pelos testes foram restaurados byte a byte; os resultados atuais foram guardados apenas nesta pasta.

O carregamento das cenas dos testes não apresentou erros de parser nos logs; isso não é uma compilação individual de todos os scripts legados/addons. Não foi necessário executar outras baterias históricas sobre cenas que não integram o fluxo principal. Não houve QA visual novo, exportação ou teste de máquina limpa. Godot AI MCP não está exposto no catálogo desta sessão; nenhum servidor foi iniciado e não se tentou recuperar a conexão. O mapa de editor fica com evidência estática atual e evidência dinâmica histórica, não revalidação visual presente.

## Lacunas e riscos de integração

- **Nenhum bloqueio P0 do gameplay confirmado nas baterias.** O produto ainda não é uma partida completa: não há enigma, progresso, saída ou vitória.
- **Estado de sala é descartado a cada travessia.** Novos enigmas não podem depender apenas de variáveis nos nós removidos. Guardar progresso por ID fora da sala e reaplicar ao instanciar.
- **Estado e reset:** EstadoJogo mistura seleção e áudio. Um estado de partida separado reduz acoplamento; definir quais dados reinício/menu/nova partida limpam antes da implementação.
- **Portas:** `opened = not target.is_empty()` ainda não expressa condição de progresso. Separar existência da aresta e permissão de atravessar, sem perder reciprocidade.
- **Expansão:** há manutenção em dois pontos (mapa.gd e cenas_salas.gd). O jogo valida cena ausente; evoluir testes para IDs extras, conectividade e caminhos considerando bloqueios. A validação geométrica atual não prova solucionabilidade de enigmas.
- **Densidade e geometria:** aumentar conexões deve respeitar adjacência e não cruzar passagens; não ligar salas arbitrariamente para atingir uma média.
- **Spawn:** safe=true não prova rota equilibrada ou objetivo acessível. Teste atual usa uma semente; não valida distribuição estatística ou todas as futuras combinações de progresso.
- **Efeitos:** mudanças de controles/câmera/luz precisam de desfazimento em saída, reinício e menu, sem conflitar com pause/fade.
- **Distribuição:** os autoloads de ferramentas permanecem na árvore; validar comportamento em export e quais recursos são necessários. Não excluir addons indiscriminadamente.
- **Conteúdo/arte:** inspeção não avalia todos os gráficos, como solicitado. Preservar assets e pausa de refinamento artístico; revisão de licenças e áudio faz parte da preparação de distribuição.
- **Históricos e testes:** alguns documentos/ferramentas ainda apontam para caminhos anteriores. Testes escrevem em pastas históricas; manter evidências futuras separadas e preservar cobertura ao introduzir portas condicionadas.

Prioridades e dependências detalhadas estão no [ROADMAP.md](ROADMAP.md); a única implementação recomendada a seguir está em [PROXIMA_TAREFA.md](PROXIMA_TAREFA.md).
