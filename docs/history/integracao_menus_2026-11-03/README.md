# Integração das telas — The Eight Doors

Abra o `project.godot` de **the-eight-doors** e execute com **F5**.

## Fluxo

Menu inicial → **Play** → escolha de **Aelin** ou **Dorian** → **Next** → sala **S01**.

- **Back** ou **Esc** na seleção retorna ao menu. A escolha permanece durante a sessão e pode ser alterada antes de iniciar outra partida.
- **WASD** movimenta o personagem. Cada escolha instancia sua própria cena de personagem, com seus sprites, animações e colisões existentes.
- **Esc** ou o botão de pausa abre a sobreposição durante o jogo. Ela oferece retomar, reiniciar a partida com o mesmo personagem, volume e retorno ao menu inicial.
- Reiniciar retorna à S01. Voltar ao menu permite escolher outro personagem.
- O volume alterna entre máximo, médio e mudo, mantendo música e efeitos sincronizados entre as telas. A trilha usa um único player persistente e continua durante a pausa.
- **Quit** encerra o jogo.

## Organização e preservação

| Conteúdo | Local no projeto unificado |
| --- | --- |
| Menu e seleção originais adaptados | `scenes/menus/` |
| Scripts de menu, seleção, estado e pausa | `scripts/ui/` |
| Todos os 25 arquivos de arte/áudio do projeto de origem | `assets/menus/` |
| Personagens jogáveis existentes | `scenes/players/` |
| Gameplay e salas existentes | `scenes/labirinto/`, `scenes/salas/` |
| Backup dos arquivos principais alterados | `backups/integracao_menus_2026-11-03/` |

O projeto `tela-de-inicio` de origem não foi modificado. O jogo unificado não depende dele. `manifesto.json` registra a transferência e comprova por SHA-256 a preservação dos 25 arquivos de arte/áudio, incluindo alternativas que já não eram usadas pelas cenas originais. Caches `.godot`, o segundo `project.godot` e metadados órfãos não fazem parte da integração.

Preservados: fundos, botões, retratos, brasas, movimento do fundo, brilho/pulso/partículas de seleção, sons e fades. Scripts e caminhos foram adaptados para o projeto principal; cenas de personagem e salas não foram redesenhadas.

## Resolução, sobreposição e correções

Os menus mantêm sua resolução lógica de **1280×720**, enquanto o labirinto mantém **640×360**. A janela usa escala proporcional, com barras quando necessário, sem alterar o zoom ou os limites da câmera do jogo. Os controles de pausa foram dimensionados para o viewport do gameplay. As artes de interface usam filtragem linear; a arte do labirinto conserva a configuração existente.

Ordem no gameplay: mundo → atmosfera (CanvasLayer 10) → HUD (11) → pausa (80) → fade de travessia (100). No menu, o fade cobre inclusive o volume. A pausa só aparece no gameplay e não pode interromper uma travessia. Controles decorativos não bloqueiam os botões.

Corrigidos na integração:

- Next sem destino de gameplay; agora confirma a escolha e abre o labirinto.
- Escolha que não era aplicada ao jogador; agora mapeia os IDs originais às PackedScenes de Aelin/Dorian.
- Perda visual da seleção ao voltar à tela; agora a seleção é restaurada.
- Corridas entre cliques repetidos, fade de entrada e saída; ações têm trava e os botões ficam bloqueados durante as trocas.
- Pausa aparecendo fora do gameplay e disputando a mesma camada do fade.
- Recorte dos cartões selecionados, ajustando a altura para acomodar o efeito de escala.
- Dependência de UID externo no autoload MCPRuntime; agora usa caminho local explícito, sem alterar seu script.
- Teste antigo que buscava o nome `SalaOctogonalBase`, incompatível com as salas herdadas S01–S06 já existentes. Agora verifica o script de sala e a instância ativa.

## Validação

`tests/test_integracao_menus.gd` verifica o fluxo completo com os dois personagens, cliques de mouse enviados ao viewport, seleção vazia, cliques duplicados, retorno, resolução, pausa e bloqueio de movimento, volume, reinício e travessia sem recriar o jogador. Foram conferidos layouts em janelas de 1280×720, 1920×1080, 800×600 e 640×360.

```powershell
& 'CAMINHO/DO/Godot_console.exe' --headless --path . --script tests/test_integracao_menus.gd
& 'CAMINHO/DO/Godot_console.exe' --headless --path . --script tests/test_labirinto.gd
```

Para capturas reais, execute o primeiro teste sem `--headless` e acrescente `-- --capture`. As imagens são gravadas nesta pasta. Os arquivos `testes_integracao.json`, `testes_visual.log` e `regressao_labirinto.log` registram os resultados; a bateria antiga grava seu relatório detalhado em `docs/history/expansao_2026-10-30/testes.json`.

Resultado final: **97 verificações de integração, 20 travessias, 38 portas seladas e 1.200 varreduras de perímetro, sem falhas**. Importação e execução renderizada concluídas sem erros nos logs finais. Todas as referências locais dos menus foram verificadas. Resumo consolidado: `resultado_final.json`.
