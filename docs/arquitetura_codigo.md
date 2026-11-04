# Arquitetura do código — The Eight Doors

## Inicialização e personagens
F5 abre `scenes/ui/menus/MenuInicial.tscn`: Play → `EscolhaPersonagem.tscn` → Next → `scenes/world/labyrinth/labirinto.tscn`. As telas, artes, áudio e efeitos vieram do projeto `tela-de-inicio`, agora incorporados em `scenes/menus`, `scripts/ui` e `assets/menus`. `EstadoJogo` guarda a escolha (`personagem_1` = Aelin; `personagem_2` = Dorian) e resolve a PackedScene correspondente. O labirinto valida o mapa e instancia essa cena; sem seleção válida, usa o campo exportado `character_scene` (Aelin por padrão). Ambas usam `personagem_top_down.gd`, com WASD, colisões e seleção das animações existentes.

S01 é o início padrão. Quando `random_spawn` está habilitado, apenas salas marcadas como seguras participam. Uma semente diferente de zero permite repetir o sorteio. Os personagens e sua câmera persistem: somente a sala visual é substituída.

## Mapa, salas e portas
`mapa.gd` separa coordenadas lógicas de pixels. Multiplicar a coordenada pelo passo (1440,1216) determina a origem física. Os portais diagonais e cardinais ficam alinhados; o validador rejeita destinos inexistentes, falta de retorno, coordenadas repetidas e sobreposição.

`sala.gd` configura uma instância da sala-base, aplicando ID e conexões. `porta.gd` controla cada Area2D: uma conexão abre a grade e remove seu bloqueio; sem destino, a porta permanece selada. A direção oposta determina a chegada: norte retorna pelo sul, nordeste pelo sudoeste e assim por diante.

## Troca e fade
Jogador → Porta → Labirinto → Fade → Carregamento → Entrada → Câmera → Retorno ao jogo.

O gerenciador valida o pedido e bloqueia novas solicitações e movimento. `transicao_fade.gd` cria um CanvasLayer persistente acima do HUD e da vinheta. O ColorRect preto passa de transparente a opaco em 0,8 s. Somente então a sala é substituída; os próximos 0,4 s permanecem pretos. A revelação leva 0,8 s. O tempo nominal total é 2 s, sujeito ao tempo de carregamento e agendamento dos frames.

O corpo reaparece no marcador interno da porta oposta. O retorno exige tempo mínimo, saída da área e afastamento para dentro. Um limite sólido externo impede acesso ao vazio. Destinos inválidos são recusados antes do fade e novamente conferidos no ponto de troca, com revelação e liberação dos controles em caso de rejeição.

## Câmera e atmosfera
`camera_exploracao.gd` configura a Camera2D filha do personagem, com zoom 1 e deslocamento local (0,-24). Labirinto soma a origem física aos limites locais da sala. Assim a câmera acompanha o personagem, mas para nas bordas da sala atual. Atmosfera não usa script GDScript: é uma cena com ColorRect e o shader existente `vinheta.gdshader`.

## Mapa no editor
Abra `scenes/world/labyrinth/mapa_editor.tscn` na aba 2D. O script `@tool` instancia as seis salas reais com base no mesmo mapa, acrescenta IDs e guias ciano das conexões. Grades indicam portas seladas. Se alterar os dados do mapa, selecione MapaEditor e clique em **Atualizar mapa** no Inspector, ou reabra a cena. Use o zoom do editor para enquadrar o conjunto. O fundo extrapolado da sala é ocultado nessa visualização para não cobrir vizinhas.

Os filhos gerados não recebem owner: são prévias transitórias, não cópias salvas da arte. Não há reconstrução por frame nem gravação automática. A cena principal permanece inalterada e não carrega essa ferramenta. Ao executar a cena de inspeção isoladamente ela não constrói gameplay.

## Auditoria dos scripts
Gameplay autoral documentado: `labirinto.gd`, `mapa.gd`, `sala.gd`, `porta.gd`, `transicao_fade.gd`, `personagem_top_down.gd` e `camera_exploracao.gd`. Os comentários explicam responsabilidades, dependências e funções sem modificar a lógica de personagem/câmera.

Ferramenta de editor: `mapa_editor.gd`. Testes: `test_labirinto.gd` e `runtime_labirinto.gd`; geradores e auditorias estão em `tools/labirinto`. Não fazem parte do gameplay. O teste MCP antigo aguarda troca instantânea; para o fade use a bateria atualizada `test_labirinto.gd`.

Históricos: `passagem_preparada.gd`, `passagem_lateral.gd` e `camera_sala_central.gd` não são usados pela expansão. Não foram comentados ou refatorados.

Autoloads de gameplay: `EstadoJogo` gerencia seleção, música e volume; `PauseOverlay` cria a pausa, reinicia a partida com o mesmo personagem e retorna ao menu. Menus usam resolução lógica de 1280×720; o labirinto mantém 640×360 e a escala proporcional do projeto. A pausa usa CanvasLayer 80, abaixo do fade 100, e recusa abertura durante travessias.

Autoloads de infraestrutura existentes: MCPRuntime (`addons/godot_mcp/runtime/mcp_runtime.gd`, agora referenciado por caminho para não depender do cache de UIDs) e `_mcp_game_helper` (`addons/godot_ai/runtime/game_helper.gd`). Seus scripts permanecem intactos. O plugin de editor Godot AI e Ziva também não foram documentados nem alterados.

## Preservação e testes
Backup dos arquivos modificados: `backups/mapa_fade_documentacao_2026-10-30/`. Não há repositório Git neste diretório. A sala-base não foi regenerada; sprites, SpriteFrames, cenas de personagens e vinheta não foram alterados.

Execute `tests/test_labirinto.gd` com a Godot em modo headless. A cobertura anterior foi mantida e a espera ampliada para concluir o fade. Cada travessia mede tempo real, verifica bloqueio do movimento e confirma opacidade total na troca física. Os resultados são gravados em `docs/history/expansao_2026-10-30/testes.json`.

Resultado final: 20 travessias, 38 portas seladas e 1.200 varreduras, sem falhas. O MCP confirmou seis instâncias de sala, seis rótulos e cinco guias; logs do editor sem erros/avisos. Uma execução concorrente apresentou pausa de agendamento de 6,455 s; a repetição completa passou sem falhas. O tempo nominal do fade não elimina pausas externas do processo.

## Integração das telas — 2026-11-03

Consulte `docs/history/integracao_menus_2026-11-03/README.md`. `tests/test_integracao_menus.gd` exercita o fluxo completo, seleção dos dois personagens, mouse, Esc, pausa, reinício, volume, redimensionamento e travessia. `test_labirinto.gd` identifica salas pelo script comum, aceitando os nomes S01–S06 das cenas herdadas.
