# Arquitetura do código — The Eight Doors

Estado atual da expansão (2026-11-09): **30 salas, 45 conexões abertas e 8 fechadas**, com saídas na S14/oeste e S21/norte. Consulte [implementação de salas e conexões](planejamento/implementacao_salas_e_conexoes.md) para edição e escopo. Os resultados datados abaixo documentam versões anteriores.

## Inicialização e personagens
F5 abre `scenes/ui/menus/MenuInicial.tscn`: Play → `EscolhaPersonagem.tscn` → Next → `scenes/world/labyrinth/labirinto.tscn`. As telas, artes, áudio e efeitos vieram do projeto `tela-de-inicio`, agora incorporados em `scenes/menus`, `scripts/ui` e `assets/menus`. `EstadoJogo` guarda a escolha (`personagem_1` = Aelin; `personagem_2` = Dorian) e resolve a PackedScene correspondente. O labirinto valida o mapa e instancia essa cena; sem seleção válida, usa o campo exportado `character_scene` (Aelin por padrão). Ambas usam `personagem_top_down.gd`, com WASD, colisões e seleção das animações existentes.

O início padrão é sorteado entre S22, S23 e S29, com chances iguais. `random_spawn = false` mantém a S01 como opção de teste. Uma semente diferente de zero permite repetir o sorteio. A posição inicial vem do marcador `Nascimento` da cena escolhida; travessias usam o marcador da porta oposta. Os personagens e sua câmera persistem: somente a sala visual é substituída.

## Mapa, salas e portas
`mapa.gd` separa coordenadas lógicas de pixels. Multiplicar a coordenada pelo passo (1440,1216) determina a origem física. Os portais diagonais e cardinais ficam alinhados; o validador rejeita destinos inexistentes, falta de retorno, coordenadas repetidas e sobreposição.

`sala.gd` configura a cena individual, herdada da sala-base, aplicando ID e conexões. `porta.gd` controla cada Area2D: uma conexão sem marcação `blocked` abre a grade e remove seu bloqueio; conexões fechadas e portas sem destino permanecem com grade e colisão. A direção oposta determina a chegada: norte retorna pelo sul, nordeste pelo sudoeste e assim por diante. E0 e D3–D9 são apenas identificadores das oito conexões fechadas, ainda sem interação de enigma.

## Troca e fade
Jogador → Porta → Labirinto → Fade → Carregamento → Entrada → Câmera → Retorno ao jogo.

O gerenciador valida o pedido e bloqueia novas solicitações e movimento. `transicao_fade.gd` cria um CanvasLayer persistente acima do HUD e da vinheta. O ColorRect preto passa de transparente a opaco em 0,8 s. Somente então a sala é substituída; os próximos 0,4 s permanecem pretos. A revelação leva 0,8 s. O tempo nominal total é 2 s, sujeito ao tempo de carregamento e agendamento dos frames.

O corpo reaparece no marcador interno da porta oposta. O retorno exige tempo mínimo, saída da área e afastamento para dentro. Um limite sólido externo impede acesso ao vazio. Destinos inválidos são recusados antes do fade e novamente conferidos no ponto de troca, com revelação e liberação dos controles em caso de rejeição.

## Câmera e atmosfera
`camera_exploracao.gd` configura a Camera2D filha do personagem, com zoom 1 e deslocamento local (0,-24). Labirinto soma a origem física aos limites locais da sala. Assim a câmera acompanha o personagem, mas para nas bordas da sala atual. Atmosfera não usa script GDScript: é uma cena com ColorRect e o shader existente `vinheta.gdshader`.

## Mapa no editor
Abra `scenes/world/labyrinth/mapa_editor.tscn` na aba 2D. A cena contém 30 instâncias de salas, 30 rótulos e 53 guias persistidos: ciano para conexões abertas e laranja para fechadas. O botão **Validar mapa** compara os dados e as posições sem reconstruir os nós. Use o zoom do editor para enquadrar o conjunto. O fundo extrapolado da sala é ocultado nessa visualização para não cobrir vizinhas.

Edite a cena de origem `scenes/world/rooms/sala_sXX.tscn` para que a personalização apareça no jogo. Ajustes feitos somente na instância da visão geral ficam restritos a ela. As prévias de grade e colisão estão salvas nas cenas individuais; o jogo reaplica o estado das conexões ao carregar cada sala. A visão geral é uma ferramenta de edição, não a cena jogável.

## Auditoria dos scripts
Gameplay autoral documentado: `labirinto.gd`, `mapa.gd`, `sala.gd`, `porta.gd`, `transicao_fade.gd`, `personagem_top_down.gd` e `camera_exploracao.gd`. Os comentários explicam responsabilidades, dependências e funções sem modificar a lógica de personagem/câmera.

O mapa do editor usa `tools/editor/mapa_editor.gd`. Os testes atuais incluem `test_labirinto.gd` e `runtime_labirinto.gd`. Geradores e auditorias antigos estão em `docs/history/tools_legadas`, com `.gdignore` para evitar a importação pela Godot. Esses scripts foram preservados para consulta e podem depender de caminhos antigos.

Históricos: `passagem_preparada.gd`, `passagem_lateral.gd` e `camera_sala_central.gd` não são usados pela expansão. Não foram comentados ou refatorados.

Autoloads de gameplay: `EstadoJogo` gerencia seleção, música e volume; `PauseOverlay` cria a pausa, reinicia a partida com o mesmo personagem e retorna ao menu. Menus usam resolução lógica de 1280×720; o labirinto mantém 640×360 e a escala proporcional do projeto. A pausa usa CanvasLayer 80, abaixo do fade 100, e recusa abertura durante travessias.

Autoloads de infraestrutura existentes: MCPRuntime (`addons/godot_mcp/runtime/mcp_runtime.gd`, agora referenciado por caminho para não depender do cache de UIDs) e `_mcp_game_helper` (`addons/godot_ai/runtime/game_helper.gd`). Seus scripts permanecem intactos. O plugin de editor Godot AI e Ziva também não foram documentados nem alterados.

## Preservação e testes
Backup dos arquivos modificados: `backups/mapa_fade_documentacao_2026-10-30/`. Não há repositório Git neste diretório. A sala-base não foi regenerada; sprites, SpriteFrames, cenas de personagens e vinheta não foram alterados.

Execute `tests/test_labirinto.gd` com a Godot em modo headless. A versão atual verifica as 30 salas, as conexões abertas e fechadas, as prévias no editor e as duas saídas. Cada travessia mede tempo real, verifica bloqueio do movimento e confirma opacidade total na troca física. Os resultados atuais são gravados em `.godot/testes_expansao.json`; os relatórios anteriores permanecem em `docs/history`.

Resultado final: 20 travessias, 38 portas seladas e 1.200 varreduras, sem falhas. O MCP confirmou seis instâncias de sala, seis rótulos e cinco guias; logs do editor sem erros/avisos. Uma execução concorrente apresentou pausa de agendamento de 6,455 s; a repetição completa passou sem falhas. O tempo nominal do fade não elimina pausas externas do processo.

## Integração das telas — 2026-11-03

Consulte `docs/history/integracao_menus_2026-11-03/README.md`. `tests/test_integracao_menus.gd` exercita o fluxo completo, seleção dos dois personagens, mouse, Esc, pausa, reinício, volume, redimensionamento e travessia. `test_labirinto.gd` identifica salas pelo script comum, aceitando os nomes S01–S06 das cenas herdadas.
