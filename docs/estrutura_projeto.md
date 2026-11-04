# Estrutura do projeto

- `scenes/ui/menus`: telas de início e seleção.
- `scenes/characters/players`: cenas de Aelin e Dorian.
- `scenes/world/labyrinth`, `rooms`, `environments`: labirinto, salas e ambientes.
- `scripts/autoload`, `ui`, `characters`, `world`, `camera`, `effects`: scripts por responsabilidade.
- `assets/characters`, `environments`, `ui`, `audio/music`, `audio/sfx`, `shaders`: arte e áudio.
- `resources`: recursos .tres.
- `tools`: ferramentas e scripts do editor; `tests`: validação.
- `docs/history`: relatórios anteriores; `docs/arquitetura_codigo.md`: arquitetura.
- `addons`: plugins preservados.

HUD e pausa continuam construídos como antes (HUD na cena do labirinto e pausa pelo autoload); não foram criadas cenas vazias apenas para preencher pastas.

Backups e revisões estão em `../arquivo-the-eight-doors`. O ZIP `antes_organizacao.zip` preserva os arquivos textuais anteriores. `organizacao_manifesto.json` lista os caminhos anteriores e novos. Não execute novamente o script de migração: a organização já foi aplicada.
