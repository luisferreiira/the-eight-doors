# Roteiro dos scripts — The Eight Doors

Guia do código atual, conferido em 10/11/2026. Os caminhos partem da raiz do projeto; `res://` é essa mesma raiz dentro da Godot. Este documento descreve o que existe hoje, distinguindo funcionalidades de jogo das propostas ainda não implementadas.

## Como ler o projeto

- **Cena `.tscn`:** guarda a árvore de nós, imagens, posições, colisões, textos, materiais e animações salvas. Abra no editor 2D para visualizar.
- **Script `.gd`:** controla comportamento, entrada do jogador e estado. Pode estar anexado a um nó, ser carregado como auxiliar ou ser um Autoload.
- **Autoload:** objeto carregado automaticamente e mantido durante as mudanças de cena. Configurado em Projeto → Configurações do Projeto → Globais/Autoload.
- **Recurso `.tres`:** configuração reutilizável, como um material.
- **Shader `.gdshader`:** programa que altera a aparência dos pixels; não controla as regras do labirinto.
- **Sinal:** aviso de um objeto para outro. Por exemplo, uma porta avisa que o personagem tentou atravessá-la.

Funções recorrentes: `_ready()` prepara o objeto quando ele entra na árvore; `_physics_process()` roda nos passos de física; `_input()` e `_unhandled_input()` recebem comandos; `@export` expõe propriedades no Inspector. `await` espera uma operação, como uma animação, terminar.

## 1. Menu inicial

**Cena:** `scenes/ui/menus/MenuInicial.tscn`  
**Script anexado à raiz:** `scripts/ui/menu_inicial.gd`

É a primeira cena aberta pelo projeto, definida em `project.godot`, na propriedade `run/main_scene`.

A cena contém fundo, sombra, partículas de brasas, botões Play/Quit e uma camada de transição. O script conecta esses elementos e anima a apresentação.

| Função/bloco | Responsabilidade |
| --- | --- |
| `_ready()` | Configura a tela de menu pelo EstadoJogo, prepara brasas, áudio, volume e botões; faz a entrada com fade. |
| `_ember_gradient()` | Define a variação de cores/transparência das brasas. |
| `_update_background_pivot()` / `_play_background_motion()` | Centralizam o pivô e fazem o movimento suave de escala do fundo. |
| `_connect_button_effects()` / `_animate_button()` / `_on_button_up()` | Conectam e animam hover, pressionamento e soltura dos botões. |
| `_on_play()` | Inicia a transição para EscolhaPersonagem.tscn. |
| `_on_quit()` | Escurece a tela antes de encerrar o jogo. |
| `_transition_to()` / `_fade_out()` | Bloqueiam cliques durante a transição, fazem o fade e trocam a cena; tratam falha ao abrir o destino. |

**Onde editar:** disposição e imagens na cena; destinos dos botões, duração dos tweens e comportamento no script. Esse script não escolhe a sala de nascimento.

## 2. Escolha de personagem

**Cena:** `scenes/ui/menus/EscolhaPersonagem.tscn`  
**Script anexado à raiz:** `scripts/ui/escolha_personagem.gd`

A cena contém os dois cartões, representações dos personagens, texto de status, botões avançar/voltar e transição. O script administra a seleção de Aelin ou Dorian.

| Função/bloco | Responsabilidade |
| --- | --- |
| `_ready()` / `_on_intro_finished()` | Preparam a tela, conectam cartões e botões, restauram uma seleção anterior e liberam os controles após o fade de entrada. |
| `_select_character()` / `_display_name()` | Guardam o ID escolhido e exibem o nome correspondente. A escolha também é escrita em EstadoJogo. |
| `_update_card_visuals()` / `_on_card_hover()` | Atualizam o destaque dos cartões conforme seleção e hover. |
| `_animate_glow()` / `_animate_card()` | Animam o brilho e a escala dos cartões. |
| `_sync_selection_effects()` / `_create_selected_particles()` / `_clear_selected_particles()` | Gerenciam pulsação e pequenos brilhos do personagem selecionado. |
| `_on_viewport_size_changed()` / `_layout_section_background_patch()` | Ajustam o layout para diferentes tamanhos e posicionam o recorte usado no fundo. |
| `_start_ambient_flicker()` | Faz uma oscilação suave na sombra ambiente. |
| `_on_next_hover()` e funções de animação dos botões | Controlam o feedback visual de avançar e voltar. |
| `_on_next_pressed()` / `_on_confirmar()` | Exigem uma seleção válida, salvam a escolha e abrem a cena de gameplay configurada no EstadoJogo. |
| `_on_voltar()` / `_unhandled_input()` | Voltam ao menu, inclusive pelo Esc. |
| `_change_scene()` / `_fade_out()` / `_set_buttons_disabled()` | Coordenam a troca de cena e evitam cliques concorrentes. |

**Estado importante:** `personagem_selecionado` identifica a escolha local; `transitioning` impede uma segunda transição. Os IDs são `personagem_1` e `personagem_2`.

**Observação:** o shader de brilho está escrito dentro deste script, na constante `GLOW_SHADER`. Alguns brilhos são criados por código; portanto, nem todos esses detalhes aparecem como nós persistidos no editor.

## 3. Estado compartilhado e áudio

**Script:** `scripts/autoload/estado_jogo.gd`  
**Carregamento:** Autoload chamado `EstadoJogo`; não depende de uma cena própria.

É o elo entre a escolha de personagem e o labirinto. Também mantém os controles de áudio durante as mudanças de tela.

- `PERSONAGENS`: associa IDs aos nomes e cenas de Aelin/Dorian.
- `personagem_selecionado`: guarda a escolha durante a execução do jogo.
- `cena_gameplay`: aponta para o labirinto.
- `cena_personagem()`: devolve a cena do personagem escolhido.
- `configurar_tela(menu)`: alterna a resolução lógica entre menus e gameplay.
- `_ready()` / `ensure_menu_music()` / `play_button_sound()`: preparam e reproduzem música e som de botão.
- `add_volume_control()`: cria o botão de volume usado pelos menus.
- `bind_volume_control()`: conecta um botão já existente em cena, como o da pausa.
- `register_volume_control()`, `_cycle_volume()`, `_apply_volume()` e `_update_volume_icon()`: sincronizam botões e alternam volume máximo, reduzido e mudo.

**Limite atual:** esse estado fica na memória; não é um sistema de salvar partida em arquivo. O progresso das portas está no labirinto, não aqui.

## 4. Entrada no labirinto e nascimento

**Cena:** `scenes/world/labyrinth/labirinto.tscn`  
**Script anexado à raiz:** `scripts/world/labirinto.gd`

Este é o coordenador da partida. A cena contém atmosfera, HUD e painel do desafio. O script carrega a sala atual, instancia o personagem escolhido e cria sua câmera.

### Inicialização e sala atual

- `_ready()`: identifica a cena como gameplay, lê EstadoJogo, conecta o painel, valida o mapa e o catálogo de cenas, prepara personagem/câmera/fade e abre a sala inicial.
- `choose_start_room()`: sorteia S22, S23 ou S29. Cada início tem a mesma chance e pode se repetir numa nova partida.
- `random_spawn`: exportado no Inspector; desativado, inicia em S01 para testes.
- `spawn_seed`: uma semente diferente de zero permite reproduzir o sorteio.
- `load_room()`: instancia a cena da sala, configura as portas, posiciona o jogador, atualiza limites da câmera e texto do HUD. Remove a sala anterior, preservando o mesmo personagem.

No primeiro carregamento, a posição vem do `Marker2D` chamado **Nascimento** na cena da sala. Ao atravessar uma porta, vem do marcador da porta de chegada.

### Travessia entre salas

- `request_transition()`: recebe o sinal da porta e verifica personagem, conexão, bloqueios e estado da partida.
- `finish_transition()`: escurece a tela, carrega o destino, revela a imagem, devolve os controles e emite `room_changed`.
- `_physics_process()`: libera a porta de chegada somente após o tempo mínimo e o afastamento do personagem; também atualiza o aviso de interação.
- `entry_lock`: evita que o personagem chegue e imediatamente atravesse de volta sem intenção.

### Interações

- `_unhandled_input()`: trata E para inscrição/saída e Esc para fechar o desafio.
- `_near_challenge()` / `_near_exit()`: verificam proximidade dos marcadores de interação.
- `_update_interaction_hint()`: escreve “E — Examinar inscrição” ou “E — Escapar” no pergaminho.
- `_lock_player()` / `blocks_pause()`: impedem movimento ou pausa em momentos incompatíveis.
- `_confirm_challenge()` / `_close_challenge()`: validam ou cancelam a interação com o primeiro enigma.

**Estado importante:** `current_room`, `transitioning`, `escaped`, `active_challenge`, `unlocking` e `solved_challenges`.

## 5. Dados do mapa e catálogo de salas

**Scripts auxiliares:** `scripts/world/mapa.gd` e `scripts/world/cenas_salas.gd`. Eles são carregados por outros scripts; não estão anexados a uma cena visual.

### mapa.gd — quais salas se conectam

- `create_rooms()`: define as 30 salas, coordenadas, conexões, bloqueios e identificação dos inícios seguros.
- `START_ROOMS`: S22, S23 e S29.
- `EXITS`: S14/oeste e S21/norte.
- `DIRECTIONS`, `OPPOSITE` e demais constantes: direções, entradas opostas e medidas usadas na geometria.
- `origin()`: converte a coordenada do mapa para posição no mundo.
- `rect_polygon()` / `passage()`: auxiliares de geometria.
- `validate()`: verifica consistência das conexões, reciprocidade, bloqueios e geometria.

### cenas_salas.gd — qual arquivo representa cada sala

`SCENES` associa S01–S30 aos arquivos `scenes/world/rooms/sala_s01.tscn` até `sala_s30.tscn`.

**Exemplo:** mudar a decoração de S22 é uma alteração na cena S22. Mudar para qual sala sua porta leva é uma alteração no mapa. Ao adicionar uma sala, é necessário criar a cena, cadastrá-la no catálogo e definir os dados/conexões.

## 6. Sala-base e salas individuais

**Base:** `scenes/world/labyrinth/sala_octogonal_base.tscn`  
**Derivadas:** `scenes/world/rooms/sala_s01.tscn` até `sala_s30.tscn`  
**Script da raiz, herdado:** `scripts/world/sala.gd`

As salas individuais herdam a estrutura compartilhada e permitem alterações locais. Não existe um script diferente para cada sala.

- `_ready()`: encontra as portas e prepara o limite físico de segurança da sala.
- `configure()`: recebe ID e dados da sala, posiciona-a e configura as portas conforme mapa e desafios já resolvidos.
- `attach_player()`: coloca o personagem na hierarquia da sala para participar da ordenação visual.

**Onde editar:** base para mudanças comuns; cena individual para decorações, posição de nascimento e características exclusivas. Os objetos avulsos têm seus corpos e polígonos de colisão salvos na cena-base.

**Exceção atual à edição visual:** os limites de segurança externos ainda são construídos pelo script em execução.

## 7. Portas e grades

**Nós:** portas `Area2D` dentro de `Passagens` na sala-base.  
**Script:** `scripts/world/porta.gd`

- `_ready()`: configura detecção do personagem e traduz a direção da porta.
- `configure()`: recebe sala, destino, ID de bloqueio e se o desafio foi resolvido; ajusta grade e colisão.
- `_entered()`: emite `requested` quando o personagem entra numa passagem aberta.
- `spawn_position()`: informa a posição do marcador `PontoEntradaFuturo`.
- `open_passage()`: anima a grade subindo e desaparecendo; só libera a colisão ao terminar.
- `opening_duration` / `opening_height`: parâmetros editáveis de duração e deslocamento.

**Divisão de responsabilidade:** a porta detecta a passagem e anima a grade; o labirinto realiza a troca de sala.

### Aparência das portas

`scenes/world/doors/visuais/porta_*.tscn` contém os visuais nas oito direções, sem script próprio. As cores usam `assets/materials/doors/vinho.tres`, `ouro.tres` e `assets/shaders/porta_tingida.gdshader`. O shader conserva a textura original e aplica a tonalidade.

`scenes/world/doors/catalogo_portas.tscn` permite comparar as variantes no editor. A cor, por si só, não abre nem bloqueia a porta; isso depende dos dados e do script.

## 8. Desafio das pedras

**Cena:** `scenes/ui/gameplay/painel_selo.tscn`  
**Script:** `scripts/ui/painel_selo.gd`

A cena guarda moldura, inscrição, sequência, botões de pedras e botões de ação. O script administra o que o jogador escolhe.

- `_ready()`: encontra os elementos e conecta botões.
- `show_challenge()`: abre o painel e limpa a seleção.
- `_select_stone()`: adiciona uma pedra, sem repetição, até completar três.
- `_clear_selection()`: limpa as escolhas.
- `_update_selection()`: atualiza a sequência mostrada e habilita confirmar apenas quando completa.
- `_confirm()`: emite `confirmed` com a sequência escolhida.
- `show_incorrect()`: mostra a mensagem de erro e limpa a tentativa.
- Sinal `dismissed`: solicita o fechamento do painel.

**A resposta correta fica em `labirinto.gd`, na constante `STONE_SOLUTION`: Estrela → Lua → Sol.** O painel não decide sozinho se a resposta está certa.

Fluxo: E perto de E0 → painel → escolha → sinal `confirmed` → `_confirm_challenge()` do labirinto → `open_passage()` da porta → registro em `solved_challenges`.

**Implementação atual:** somente E0 tem enigma funcional. Os outros bloqueios cadastrados permanecem fechados. Erros mostram uma mensagem; ainda não descontam vida. Acertos ainda não concedem pontuação. O progresso é compartilhado pelos dois lados de E0 durante a partida e é perdido ao reiniciar.

## 9. HUD e pergaminho

**Contexto:** nó `HUD` de `labirinto.tscn`.  
**Cena reutilizável:** `scenes/ui/gameplay/pergaminho.tscn`, sem script próprio.

O texto da sala/personagem é atualizado em `load_room()`. O texto e a visibilidade do pergaminho são controlados por `_update_interaction_hint()` e `_physics_process()` do labirinto.

O pergaminho hoje apresenta comandos de interação. A distribuição estratégica de dicas de navegação ainda não está implementada.

## 10. Saídas e vitória

**Cenas:** `scenes/world/doors/saida.tscn`, `saida_norte.tscn`, `saida_oeste.tscn` e `placa_saida.tscn`, sem scripts próprios.

Elas guardam a sinalização e o marcador `Saida/Interacao`. O labirinto verifica a proximidade desse marcador e, ao pressionar E, bloqueia o personagem e solicita a tela de vitória.

**Tela:** `scenes/ui/gameplay/vitoria.tscn`, sem script próprio. É instanciada por `painel_selo.gd`, em `show_victory()`, que recebe as ações de reiniciar e voltar ao menu do labirinto.

**Diferença atual:** os botões da vitória chamam recarregamento/menu diretamente. O fade específico do reinício descrito abaixo pertence ao fluxo da pausa.

## 11. Pausa, reinício e volta ao menu

**Cena visual:** `scenes/ui/gameplay/pausa.tscn`  
**Script controlador:** `scripts/autoload/pause_overlay.gd`, Autoload chamado `PauseOverlay`.

O script não precisa estar anexado à cena de pausa: ele a instancia e conecta seus nós. O layout da moldura, título, botões, legendas e volume fica salvo na `.tscn`.

- `_ready()` / `_build_ui()`: instanciam as cenas e conectam ações.
- `_is_gameplay()` / `_refresh_for_scene()`: mostram a interface apenas durante o jogo e sincronizam o estado.
- `_pause_game()`: verifica se pode pausar, congela a árvore e mostra o painel.
- `_resume_game()`: retoma a partida.
- `_restart_current_scene()`: inicia o reinício.
- `_return_to_menu()`: inicia a volta ao menu.
- `_change_scene()`: escurece a tela, troca/recarrega a cena, revela e libera os controles.
- `_input()`: trata Esc e bloqueia entradas durante a transição.

**Fade da pausa:** `scenes/ui/gameplay/fade_reinicio.tscn`, sem script próprio; contém camada, retângulo preto e `AnimationPlayer`. As animações `escurecer` e `revelar` são comandadas pelo Autoload.

Ao reiniciar, o personagem escolhido permanece no EstadoJogo; o labirinto novo refaz o sorteio de nascimento e limpa seu progresso local.

## 12. Movimento dos personagens

**Cenas:** `scenes/characters/players/aelin.tscn` e `dorian.tscn`  
**Script compartilhado:** `scripts/characters/personagem_top_down.gd`

- `_ready()`: prepara o modo de movimento e a animação inicial.
- `_physics_process()`: lê as ações direcionais, calcula velocidade e chama `move_and_slide()` para movimentar com colisão.
- `_update_animation()`: escolhe animação parada/correndo e direção do personagem.
- `speed`: velocidade editável no Inspector.
- `idle_prefix`: prefixo das animações paradas.
- `controls_enabled`: permite que o labirinto suspenda o movimento em transições e desafios.

As teclas são configuradas no Input Map de `project.godot`: WASD para movimento e E para interação; Esc usa `ui_cancel`.

## 13. Câmera e fade de travessia

**Câmera:** `scripts/camera/camera_exploracao.gd`. O labirinto cria uma Camera2D como filha do personagem e associa esse script. `_ready()` define enquadramento e opções da câmera; os limites da sala são atualizados por `load_room()`.

**Transição de sala:** `scripts/effects/transicao_fade.gd`. É instanciado pelo labirinto e cria sua camada preta. `escurecer()` cobre a tela; `revelar()` espera brevemente e remove a cobertura.

Existem três implementações de fade no fluxo atual: transições dos menus em seus próprios scripts; travessias em `transicao_fade.gd`; reinício/retorno da pausa em `fade_reinicio.tscn`. Alterar uma não altera automaticamente as outras.

## 14. Chão, tochas e atmosfera

| Cena/recurso | Script? | Funcionamento |
| --- | --- | --- |
| `scenes/world/environments/detalhes_piso.tscn` | Sem `.gd` | Decoração de piso com nós salvos, como fissuras e pedrinhas. |
| `scenes/world/environments/tocha_animada.tscn` | Sem `.gd` | Sprite, luz e AnimationPlayer; a animação `tremular` varia a chama e a energia da luz. |
| `assets/shaders/chama_tocha.gdshader` | Shader | Deforma a parte da chama usando parâmetros animados, preservando o suporte. |
| `scenes/world/environments/atmosfera.tscn` | Sem `.gd` próprio | Aplica a apresentação atmosférica. |
| `assets/shaders/vinheta.gdshader` | Shader | Produz a vinheta visual. |

Não é necessário ter um GDScript em toda cena animada: AnimationPlayer e materiais também implementam efeitos. Os obstáculos avulsos usam colisões físicas salvas na sala-base.

Controles invertidos estão ativos em S06/S07. A cena `scenes/world/effects/controles_invertidos.tscn` usa `scripts/world/efeito_sala.gd`, com a pista rimada exportada no Inspector. O labirinto redefine a inversão ao trocar de sala. A primeira implementação de chão falso foi removida a pedido do usuário; S02/S08 voltaram ao piso normal. Super zoom e escuridão como dificuldade continuam planejados.

## 15. Visão geral no editor

**Cena:** `scenes/world/labyrinth/mapa_editor.tscn`  
**Script:** `tools/editor/mapa_editor.gd`

O `@tool` permite executar o script no editor. O botão **Validar mapa** chama `validate_map()`, compara as salas salvas com os dados de `mapa.gd` e informa inconsistências. Ele não reconstrói nem apaga as edições do mapa.

Essa cena serve para visualizar a distribuição. O jogo carrega as cenas individuais por `cenas_salas.gd`. Para mudar uma sala também no jogo, edite sua cena de origem; uma alteração feita somente na instância da visão geral pode ficar restrita a essa prévia.

## 16. Arquivos de suporte e versões anteriores

- `scripts/world/passagem_preparada.gd`: guarda dados de uma passagem futura; ainda é referenciado em `scenes/world/environments/sala_central_jogavel.tscn`. Não é o controlador das portas do labirinto atual.
- `scripts/world/passagem_lateral.gd`: controlador simples que alterna bloqueio e emite um sinal de passagem. Não foi encontrada referência a ele nas cenas atuais pesquisadas.
- `scripts/camera/camera_sala_central.gd`: enquadramento automático de uma sala inteira. Não foi encontrada referência a ele nas cenas atuais pesquisadas; a exploração usa `camera_exploracao.gd`.
- `tests/`: verificações automatizadas e cenas/scripts de teste; não são o fluxo normal da partida.
- `docs/history/tools_legadas/`: ferramentas históricas de montagem/auditoria, separadas do funcionamento normal do jogo.
- `addons/`: integrações de desenvolvimento. Os Autoloads MCPRuntime e `_mcp_game_helper` vêm dessas integrações, não das regras de personagens, portas ou desafios.
- `.gd.uid`: identificadores de recursos usados pela Godot, não outros scripts de comportamento.

## Consulta rápida: onde mexer

| Quero alterar… | Começar por… |
| --- | --- |
| Aparência do menu | `scenes/ui/menus/MenuInicial.tscn` |
| Ações/animações do menu | `scripts/ui/menu_inicial.gd` |
| Tela de seleção | `scenes/ui/menus/EscolhaPersonagem.tscn` e `scripts/ui/escolha_personagem.gd` |
| Cadastro de personagens e áudio | `scripts/autoload/estado_jogo.gd` |
| Velocidade e animações de movimento | `scripts/characters/personagem_top_down.gd` e cenas dos personagens |
| Quais salas podem iniciar a partida | `START_ROOMS` em `scripts/world/mapa.gd` |
| Como o início é sorteado | `choose_start_room()` em `scripts/world/labirinto.gd` |
| Posição exata de nascimento | Marcador Nascimento na cena individual |
| Conexões e bloqueios | `scripts/world/mapa.gd` |
| Decoração de uma sala | `scenes/world/rooms/sala_sXX.tscn` |
| Estrutura e obstáculos comuns | `scenes/world/labyrinth/sala_octogonal_base.tscn` |
| Abertura da grade | `scripts/world/porta.gd` |
| Cor das portas | Cenas em `scenes/world/doors/visuais/` e materiais em `assets/materials/doors/` |
| Aparência/texto do enigma | `scenes/ui/gameplay/painel_selo.tscn` |
| Botões e sequência escolhida | `scripts/ui/painel_selo.gd` |
| Resposta correta e consequência | `scripts/world/labirinto.gd` |
| Pergaminho | `scenes/ui/gameplay/pergaminho.tscn`; conteúdo no labirinto |
| Placa e posição de interação da saída | Cenas de saída e instâncias em S14/S21 |
| Layout da pausa | `scenes/ui/gameplay/pausa.tscn` |
| Ações da pausa | `scripts/autoload/pause_overlay.gd` |
| Fade ao reiniciar pela pausa | Animações de `scenes/ui/gameplay/fade_reinicio.tscn` |
| Animação das tochas | `scenes/world/environments/tocha_animada.tscn` |

## Ordem sugerida de leitura

`menu_inicial.gd` → `escolha_personagem.gd` → `estado_jogo.gd` → `labirinto.gd` → `mapa.gd` e `cenas_salas.gd` → `sala.gd` → `porta.gd` → `personagem_top_down.gd` → `painel_selo.gd` → `pause_overlay.gd` → câmera, fades e shaders.

Abra a cena correspondente ao lado do script: isso permite relacionar cada caminho de nó usado no código ao elemento visual que ele controla.
