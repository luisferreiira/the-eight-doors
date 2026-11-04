# Ajuste localizado das entradas Leste e Oeste

Cena corrigida: `res://scenes/dungeon/sala_central_referencia.tscn`.

Apenas os dois pórticos laterais foram recompostos. A cena `scenes/world/environments/fase_caverna.tscn`, as outras seis portas, o piso, o alçapão, os pilares, as tochas, as pedras, as teias e a câmera foram preservados.

## Arquivos modificados

- `scenes/dungeon/sala_central_referencia.tscn`: somente o PackedByteArray da camada Portas, um Atlas Source complementar referenciando a mesma textura e quatro colisões pequenas nas bases das molduras.
- `tools/dungeon_central/validar_cena.gd`: teste atualizado para reconhecer portas compostas por várias células, verificar a opacidade dos túneis e testar as bases das molduras.

Os arquivos anteriores foram copiados para `backups/entradas_laterais_2026-10-25_6531f73e/` antes da alteração no projeto.

## Tiles reutilizados

Nenhum PNG, atlas ou TileSet externo foi modificado ou duplicado. Os fragmentos vêm do próprio `assets/environments/generated/dungeon_central/atlas_sala_central.png` usado pela sala: arco, soleira, ombreiras e degraus do pórtico frontal; faces de pedra do capitel do pilar; tijolos do painel frontal.

A nova fonte `ComponentesEntradasLaterais` seleciona apenas células de 16×16 da mesma imagem. Uma alternativa de tile escurece os tijolos internos. As regiões e configurações da fonte original do TileSet permanecem literais e inalteradas. Não foi criado um atlas genérico, uma nova sala ou uma textura de fundo.

Cada entrada ocupa 128×192 px, sem redimensionamento dos pixels de origem. Oeste: canto em (0,464); Leste: canto em (992,464). O lado voltado para o interior tem tijolos sombreados e um suporte vertical. O lado oposto tem blocos de pedra. O arranjo do Leste foi recomposto com a ombreira oposta, preservando o sentido de iluminação dos sprites; não foi aplicada escala negativa no conjunto. Os degraus ficam abaixo de uma área preta opaca.

## Colisões e profundidade

As aberturas e os limites físicos anteriores foram mantidos. Quatro pequenos polígonos adicionais, de 32×16 px, dão solidez às bases dos apoios. Como nos pilares da sala, a parte alta desenhada da moldura não representa uma caixa de colisão ocupando toda a imagem: o personagem pode entrar atrás da estrutura elevada, sem atravessar sua base.

Não há personagem ou sistema de transição em sala implementado no estado atual deste projeto. Não foram inventadas transições nem alterados controles. A validação usou consultas físicas e um corpo circular de 16 px; a futura integração de um personagem maior deve conferir raio e ordenação por profundidade.

## Verificações executadas

A cena corrigida foi carregada, executada e capturada na Godot 4.7.1 stable oficial, usando OpenGL Compatibility. O teste passou sem falhas para recortes, grade 16×16, opacidade do interior, bases sólidas, entradas livres e caminhos A* até as oito saídas. O resultado está em `validacao_entradas_laterais.json`.

A comparação textual confirma que os outros 51 blocos de nós existentes permanecem literais; a fonte original de tiles e os demais subrecursos também foram preservados. A captura antes/depois, na mesma resolução e câmera, encontrou 45.509 pixels alterados dentro das duas entradas e **zero pixels alterados fora delas**. Veja `comparacao_visual_laterais.json` e `comparacao_entradas_laterais.png`.

## Limitações e manutenção

A composição reaproveita fragmentos disponíveis e não copia a referência pixel a pixel. Os blocos conservam as juntas e o detalhe nativo do pacote. Não foi acrescentada uma teia, pois a decoração próxima já existente foi preservada.

A ferramenta antiga `montar_cena.gd` reconstrói a versão anterior da sala a partir do manifesto antigo. Esta é uma correção localizada na cena final; não execute essa reconstrução sobre a cena corrigida sem preservar a versão atual. O ZIP da entrega anterior continua representando a versão anterior; esta correção está salva diretamente na cena do projeto.
