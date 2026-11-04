# Correção visual — estado desta etapa

A tarefa completa ainda não está concluída: os ciclos gráficos de caminhada precisam ser reconstruídos e validados. Não foram substituídos por versões improvisadas.

## Implementado

A cena atual `scenes/world/environments/sala_central_jogavel.tscn` foi editada diretamente, sem executar os geradores que restauram backups antigos. Foram transferidas 43 células de Paredes e 8 de Portas para suas respectivas camadas frontais existentes. A separação anterior começava em y=704, mas as faces dos cantos inferiores começam em y=640. As coordenadas, recursos e tiles foram preservados, sem duplicação. Nenhum novo z-index foi aplicado.

As capturas `depois_canto_esquerdo.png` e `depois_canto_direito.png` mostram a ocultação parcial real de Aelin pelos muros. As demais capturas cobrem centro, parede inferior e portas. Renderização sem erros. Testes locais: 192 varreduras do perímetro, 16 verificações de pilares, oito direções, nenhuma falha.

## Preservação

Backups em `backups/animacoes_visual_20261027`, incluindo a cena atual, ambas as cenas dos personagens e o controlador. `estado_inicial.json` registra SHA-256 dos arquivos em scenes, assets, tools, tests e project.godot. Não há diretório .git nesta cópia; portanto não é possível distinguir arquivos rastreados de não rastreados por Git.

A posição personalizada de Aelin (556,543), câmera, zoom, vinheta, fullscreen, controles, portas e decorações foram conservados. Scripts de jogo, cenas dos personagens e imagens originais não foram modificados nesta etapa.

## Animações: diagnóstico, ainda sem correção gráfica

`auditoria_frames.png` apresenta os quatro quadros de cada um dos oito ciclos de corrida dos dois personagens, ampliados com nearest. Os ciclos mostram poses muito semelhantes e alternância insuficiente das pernas. Não basta mudar FPS. Os recortes atuais têm 64x64; o controlador preserva idle, direção e velocidade diagonal, e não reinicia play a cada frame. Não foram gerados novos frames nem declarada uma correção das animações.

A gravação disponível no histórico pertence à etapa anterior da câmera. Não há nova gravação anexada a este pedido; ela não comprova a qualidade de ciclos reconstruídos.

## Limitações verificadas

A tentativa atual de editor_state via Godot AI MCP retornou PLUGIN_DISCONNECTED, registrada em estado_mcp.json. Os testes e capturas desta etapa foram realizados diretamente pelo executável local Godot 4.7.1. Faltam a reconstrução dos ciclos de ambos os personagens, inspeção de ciclos completos em movimento, validação separada de Dorian e nova validação via MCP conectado.

Arquivos de apoio adicionados: tools/dungeon_central/auditar_visual_atual.gd, corrigir_cantos_atuais.gd e capturar_cantos_atuais.gd. O único arquivo de produção modificado nesta etapa foi a cena jogável.
