# Dungeon jogável, Aelin e Dorian — 26/10/2026

## Abrir e jogar

Abra `res://scenes/world/environments/sala_central_jogavel.tscn` e execute a cena atual com F6. WASD move Aelin; duas teclas adjacentes produzem diagonais. Não há pulo nem gravidade. A cena principal global do projeto não foi alterada.

Godot verificada: **4.7.1-stable (official)**. Godot AI: **4.3.1**, consultas e comandos reais pelo protocolo MCP via bridge local stdio. O catálogo nativo desta conversa não expõe godot-ai; as chamadas foram feitas por um cliente de diagnóstico local, com evidências JSON copiadas nesta pasta.

## Diagnóstico e correções

Aelin e Dorian já eram CharacterBody2D, com AnimatedSprite2D e oito animações cada: caminhada e idle nas quatro direções. Não havia script de controle nem ações personalizadas no Input Map. As cápsulas de 128/140 pixels de largura e 274/300 de altura eram incompatíveis com as passagens. Recortes originais variavam de tamanho e origem entre estados e algumas divisões cortavam margens do personagem.

As cenas originais dos personagens foram corrigidas e continuam reutilizáveis. Ambas usam `scripts/characters/personagem_top_down.gd`, com velocidade exportada de 144 px/s, Input.get_vector, CharacterBody2D.MOTION_MODE_FLOATING e move_and_slide. Animações não reiniciam a cada frame. Ao parar, cada personagem mantém o idle da última orientação. Em diagonais de empate, conserva a cardinal anterior quando ela pertence ao par; caso contrário usa a vertical. Não foram inventados quadros diagonais.

Os 16 spritesheets originais foram preservados. As cópias em `assets/generated/personagens/` têm quatro células de 64×64, redução com vizinho mais próximo e alinhamento inferior. A escala é fixa entre os estados de cada personagem. O manifesto registra os recortes, escala e SHA-256 de cada original. Foram preservados nomes, ordem e quatro quadros por animação. Caminhada a 8 FPS, idle a 5 FPS. Filtragem nearest no personagem e na sala.

As cápsulas agora têm raio 8, altura 18, centro em (0,-6), com layer 2 e mask 1. Cabelo e capa ficam fora do volume físico. O sprite usa posição (0,-32), com a origem do personagem na área dos pés.

## Dungeon e portas

A referência original permanece byte a byte igual ao backup. A cópia jogável conserva piso, paredes, oito entradas originais, colunas, tochas, grade e decoração. Corrige os transforms deslocados/escalados das duas colisões oeste, abre 20 tiles do plano de parede e dá continuidade ao piso nas duas passagens.

- `Passagens/Porta_Leste`: origem (1056,576), abertura na parede direita.
- `Passagens/Porta_Oeste`: origem (64,576), abertura na parede esquerda.

As duas são Area2D com batentes de pedra e soleiras montados com recortes do atlas complementar C. Não foram girados sprites de portas norte/sul. Cada uma tem zona de detecção, marcador PontoTransicao, bloqueio físico desativado enquanto aberta e limites físicos para o corredor. `passagem_lateral.gd` oferece `set_aberta`, destino exportado e sinal `passagem_solicitada(personagem,destino)`. Ainda não há troca de sala configurada, conforme preparação para transições futuras; os corredores terminam antes do vazio.

A referência apontava para a textura inexistente `assets/TheEightDoors_TileMapLayer/preview_murinho.png`. A imagem já importada foi recuperada do cache da Godot em um novo PNG: `assets/environments/generated/dungeon_central/refino/murinho_recuperado.png`. Apenas a cópia jogável aponta para ele. Não há dependência do cache no jogo final.

O piso e detalhes planos ficam atrás dos atores; o Y-sort compartilha a cadeia dos personagens e colunas. Aelin é uma instância real de `scenes/characters/players/aelin.tscn`, em (560,672), área livre. Dorian não integra a dungeon.

## Câmera

Reutilizada a única Camera2D e o script existente `camera_sala_central.gd`, sem alterar esse script. Enquadramento estático da sala com margem, área Rect2(-96,-32,1312,1104), para incluir as passagens. Não há câmera concorrente nem seguimento com suavização. O tamanho visual dos personagens é de até 56 px, compatível com a grade de 16 px e os vãos de 96 px.

## Testes

`tests/test_dungeon_jogavel.gd` executa na Godot testes de ambos os personagens contra a sala real. Última execução: **zero falhas**, stderr vazio. Os resultados estão em `testes_automatizados.json`.

Verificados: oito direções, vetor a 45 graus, velocidade física de 144 px/s em todas elas, cancelamento de direções opostas, eventos de tecla W/S/A/D reconhecidos pelo Input Map, idle com última orientação, avanço de quadros, oito animações com quatro quadros, cápsulas compactas, paredes leste/oeste, pilares, travessia das duas passagens abertas e bloqueio das portas fechadas. O deslocamento por janela de teste fica em cerca de 48 px; pode variar um tick no agendamento do teste, sem alterar a velocidade física medida.

Renderizações reais da Godot revisadas visualmente: `sala_jogavel.png` e `personagens_godot.png`. A inspeção visual confirma a composição da sala, Aelin instanciada e as quatro orientações de Aelin e Dorian. Capturas estáticas não são apresentadas como validação visual de cada quadro de animação; o avanço e seleção dos estados foram também verificados em execução pelos testes.

O Input Map foi criado com `input_map_manage(op=ensure_binding)` por MCP. A cena foi aberta com `scene_open` e executada com `project_run(autosave=false)`. `editor_state` confirmou `helper_live=true`, `game_capture_ready=true`, `status=live`, sem erros de inicialização da cena. Um script temporário de avaliação MCP teve erro de indentação e pausou a depuração; foi corrigido e a execução reiniciada. Isso não alterou os scripts do jogo. A avaliação corrigida depois passou para os dois personagens.

`tests/preview_dorian.tscn` permite executar Dorian isoladamente com a mesma cena reutilizável, em um espaço limpo e câmera própria de teste. Não adiciona Dorian à dungeon.

## Preservação e arquivos

Backup: `backups/dungeon_personagens_2026-10-26/` (project.godot, cenas de Aelin e Dorian, referência, mais .gdignore). Não havia scripts de movimento antigos a copiar. Nenhum recurso original foi removido.

`preservacao_e_recursos.json` confirma: referência intacta, 16 spritesheets originais intactos, nenhuma referência externa ausente nas três cenas finais e somente o Input Map alterado nas configurações globais. SHA-256 da referência: `45cc4ef107a53e98473c777834ba1ff2f38acd23b11c27c9259382327bbac924`.

A relação completa dos arquivos autorais, metadados de importação/UID e evidências está em `arquivos_alterados.json`. A pasta `.godot` contém caches gerados automaticamente e não faz parte dos arquivos autorais.

## Pendências de conteúdo

Os assets oferecem quatro orientações, portanto as diagonais usam animações cardinais coerentes. Destinos de outras salas ainda precisam ser atribuídos e conectados ao sinal de passagem quando essas salas forem implementadas. A cena de referência conserva sua referência de textura antiga, por exigência de preservação; use a cópia jogável para executar sem esse recurso ausente.

## Validação final MCP dos controles

Aelin foi testada na dungeon em execução; Dorian foi aberto no editor e executado isoladamente em preview_dorian.tscn. editor_manage(op=game_eval) injetou eventos InputEventKey de W, S, A, D e das quatro combinações diagonais para cada um. As 16 amostras retornaram velocidade física de 144 px/s e estados de caminhada/idle coerentes. Os resultados estão em mcp_aelin_controles.json e mcp_dorian_controles.json. editor_screenshot(source=game) também retornou captura atual, stale_frame=false, para a dungeon. Nenhuma verificação de controle obrigatória ficou pendente de teste manual.

A última execução também confirmou sete cenários de colisão por MCP (mcp_colisoes.json): passagens abertas atravessadas em aproximadamente 144 px, paredes e portas fechadas interrompendo o deslocamento em aproximadamente 74 px, e pilar interrompendo em 45 px. logs_read(source=game) retornou somente a mensagem informativa de registro do helper, sem erros ou avisos; status live (mcp_logs_final.json). As duas portas foram restauradas abertas e Aelin voltou ao ponto inicial após os testes.
