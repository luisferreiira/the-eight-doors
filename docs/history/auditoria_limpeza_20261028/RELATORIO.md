# Auditoria e limpeza — The Eight Doors — 28/10/2026

## Resultado

1.941 arquivos analisados, 313.486.878 bytes antes da limpeza (incluindo cache e ferramenta de auditoria). 243 grupos de hashes duplicados, com 285 copias adicionais. Nenhum grupo foi tratado automaticamente como dispensavel.

Classificacao conservadora: A = 781 arquivos / 206.176.320 bytes; B = 95 / 26.334.241 bytes; C = 1.064 / 80.976.317 bytes; D = 1 / 0 bytes. A inclui dependencias preservadas por precaucao, nao apenas recursos comprovadamente usados no gameplay. B inclui fontes e recursos futuros. C inclui cache, testes e materiais de desenvolvimento.

Inventario completo: inventario.json. Cada registro inclui caminho, bytes, hash, categoria, motivo e referencias identificadas. Grupos completos: duplicatas.json. Pontos de acesso dinamico: cargas_dinamicas.json. Ausencia de referencia literal nao e prova de inutilidade; caminhos construidos e acessos nativos permanecem conservadoramente preservados.

## Exclusao executada

- docs/history/animacoes_visual_20261027/captura_erros.log — log historico vazio (0 bytes), sem referencia identificada. Tamanho reconfirmado imediatamente antes da exclusao.
- Espaco recuperado: **0 bytes**. Nao houve reducao material. Relatorios e logs novos aumentam ligeiramente o tamanho final.
- Backup: desnecessario para este arquivo vazio, integralmente recriavel. Restauracao a partir da raiz: `New-Item -ItemType File -Path docs/history/animacoes_visual_20261027/captura_erros.log`.
- Nenhum outro asset, candidato, backup, log com conteudo ou cache foi removido/movido.

## Validacao

Godot 4.7.1 executada em modo headless com tools/validar_limpeza.gd. Carregou e instanciou scenes/characters/players/aelin.tscn, scenes/characters/players/dorian.tscn e scenes/world/environments/sala_central_jogavel.tscn; percorreu as texturas de todos os SpriteFrames dos personagens. Resultado: count=0, failures=[]. Evidencia: godot_validation.log.

O teste carregou recursos da dungeon, incluindo dependencias de texturas, TileSets e scripts. Nao foi uma auditoria visual, nem teste de movimento/colisoes, nem reimportacao completa do editor. Godot AI MCP nao estava disponivel como ferramenta nesta sessao.

Os hashes posteriores estao em verificacao_final.json. Os arquivos de gameplay, imagens, cenas, plugins, candidatos, backups e a protecao de preparar_quadros.py foram preservados. Os dados do teste foram direcionados para runtime_profile dentro desta pasta.

Referencia ausente preexistente: scenes/dungeon/sala_central_referencia.tscn, citada por metadata/referencia_preservada na dungeon jogavel. E metadado, nao dependencia ext_resource; a dungeon carregou com sucesso. Investigar sua finalidade antes de corrigir ou apagar esse metadado.

## Plugins e maiores oportunidades

- Godot AI 4.3.1 habilitado. Preservado.
- Godot MCP 0.6.0 desabilitado como EditorPlugin, mas o projeto possui autoload MCPRuntime por UID; nao presumir inatividade total. Preservado.
- addons/.godot_ai_update/backup/3.2.1: copia de migracao/recuperacao. Preservada.
- Ziva Agent: registrado em .godot/extension_list.cfg como GDExtension; portanto nao deve ser julgado apenas pela lista de EditorPlugins. zivacode.exe ocupa 122.850.816 bytes. Preservado.
- DLL principal do Ziva e duas variantes temporarias identicas: 7.907.840 bytes cada. Identidade confirmada por hash, mas variantes com ~ e .TMP podem participar de substituicao/carregamento nativo. Nao excluidas. Revisar com o editor fechado e o fluxo de atualizacao da extensao conhecido.
- assets/personagens/personagem.zip (13.452.399 bytes), PSDs, pacotes de dungeon e originais: preservar como fontes de desenvolvimento.

## Organizacao futura

Manter assets/personagens como fontes e assets/generated/personagens como producao. Materiais de art_reviews continuam em revisao ate aprovar e integrar as animacoes. Nao houve limpeza dessas pastas.

Arquivamento externo de backups, capturas e revisoes pode reduzir espaco, mas depende de uma pasta externa explicitamente autorizada; nenhuma foi utilizada. Evitar novas copias completas quando um manifesto de hashes e arquivos alterados bastarem. Manter a saida historica do gerador isolada como esta.

Uma eventual reducao grande depende de decidir o futuro de plugins volumosos ou arquivar fontes e revisoes, nao de apagar recursos sem referencia textual. Cache .godot, .uid e .import foram preservados.
