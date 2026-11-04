# The Eight Doors — nova sala central

Cena: `res://scenes/dungeon/sala_central_referencia.tscn`.

Abra esta cena no projeto e use F6. A cena original `scenes/world/environments/fase_caverna.tscn`, o `project.godot` original, os atlas e os scripts anteriores foram preservados. O documento `originais_preservados_sha256.json` registra os hashes conferidos antes e depois da criação.

## Organização

```
SalaCentralReferencia (Node2D)
├── Fundo (Polygon2D)
├── Piso (TileMapLayer)
├── TransicoesPiso (TileMapLayer)
├── Entulho (TileMapLayer)
├── Tunel (TileMapLayer)
├── Paredes (TileMapLayer)
├── Molduras (TileMapLayer)
├── Portas (TileMapLayer)
├── SombrasElementos (TileMapLayer)
├── Elementos (TileMapLayer)
├── Colisoes (StaticBody2D: 16 trechos de parede + 4 bases de pilar)
├── Entradas (8 Marker2D: N, NE, L, SE, S, SO, O, NO)
├── Iluminacao (CanvasModulate + 8 PointLight2D)
└── Camera2D
```

Todas as peças visuais repetidas estão pintadas nas camadas. Os únicos objetos repetidos como nós são luzes, marcadores de saída e polígonos físicos, que precisam de propriedades próprias. Não há um Sprite2D ou nó por tijolo/pedra/célula.

## Recursos e grade

TileSet exclusivo: `res://resources/generated/dungeon_central/sala_central_tileset.tres`.
Atlas novo: `atlas_sala_central.png`, 1024 × 448 px, RGBA, grade de 16 × 16 px, 47 regiões cadastradas. Regiões maiores ocupam várias células. O manifesto informa coordenadas e tamanho de cada peça. Todas as camadas usam Nearest; não há escala em sprites nem redimensionamento dos atlas originais.

Foram reutilizados pixels nativos dos atlas complementares A/C já existentes no projeto. Eles fornecem terra, lajes, paredes frontais/diagonais, pórticos, pilares, grade central, pedras, tijolos, teias e tochas. O atlas original `RF_Catacombs_v1.0/mainlevbuild.png` fornece os dois pequenos respiros metálicos. O `decorative.png` original foi inspecionado e preservado, mas não foi necessário nesta composição.

Os novos recortes removem fragmentos externos e corrigem a transparência em cópias. As peças diagonais são originais inclinadas ou espelhadas horizontalmente; nenhuma porta foi girada em 45° ou esticada. Fatias de 16/32 px fecham junções, preservando os pixels em escala 1:1. A única imagem desenhada por código é uma sombra elíptica discreta sob os pilares. Os halos de luz usam GradientTexture2D da própria Godot.

## Arquitetura e circulação

Há quatro pórticos frontais cardeais e quatro pórticos inclinados nas faces diagonais. Os pórticos L/O são pequenos vestíbulos salientes; a projeção lateral deles é uma simplificação coerente com a arte frontal disponível. Os túneis ficam atrás dos pórticos. A sala mantém terra predominante, manchas irregulares de lajes, oito grupos principais de entulho e espaço livre no centro.

Os quatro pilares e a grade têm centro de composição em (560, 544). As posições dos pilares são simétricas. A câmera se ajusta ao tamanho da janela por um script exclusivo; não modifica resolução, cena inicial ou configurações do projeto.

As colisões usam layer 1/mask 1 e são polígonos independentes das áreas visuais altas. Isso evita que uma porta, sua escadaria ou o desenho elevado de uma coluna bloqueie uma área que deveria ser transitável. As paredes possuem 16 segmentos físicos, divididos ao redor das oito aberturas de 96 px. Os quatro pilares bloqueiam só a base. Terra, lajes, entulho decorativo, túneis e grade central não recebem colisão.

## Validação realizada

Godot 4.7.1 stable oficial, build a13da4feb. A cena foi criada pela API nativa, salva como PackedScene, carregada novamente e executada com OpenGL Compatibility. A imagem `sala_central_render_godot.png` é uma captura real do viewport em 1280 × 1088, não uma simulação ou a referência usada como fundo.

Passaram os testes de carregamento, grade, recortes dentro do atlas, camadas, oito peças de porta, oito marcadores, vinte polígonos físicos, parede sólida, bases de pilares sólidas, alinhamento da grade e simetria dos pilares. Raios cruzam livremente cada abertura. Uma busca A* com consultas de colisão para um corpo circular de 16 px encontrou caminho da área central até as oito saídas. `validacao_godot.json` contém o resultado sem falhas.

As primeiras tentativas de importar em sandbox mostraram avisos de acesso ao diretório user://. A captura final foi executada com acesso ao cache gráfico e terminou sem erro. Nenhum teste abriu a cena original nem seus addons.

## Limitações

Não há personagem ou script de movimentação próprio no estado inspecionado do projeto. Por isso não foi integrado um jogador nem alterados controles; a circulação foi verificada com um corpo de teste de 16 px. Se um personagem maior for adicionado, confirme o raio da colisão e a ordenação por profundidade.

As tochas usam quadro estático e luzes 2D; não há animação de chama nem sombras dinâmicas de parede. As sombras dos pilares são discretas e estáticas. O desenho é uma aproximação modular da referência, com pórticos L/O frontais e escala dos novos recortes complementares preservada. Não é uma reprodução pixel a pixel da referência.

## Ferramentas opcionais

`tools/dungeon_central/montar_cena.gd` reconstrói somente esta cena e seu TileSet novo a partir do atlas/manifesto.
`validar_cena.gd` executa as verificações físicas/estruturais.
`capturar_cena.gd` executa e captura a nova cena. As ferramentas não são necessárias para jogar/abrir a sala.

## ZIP e instalação

O ZIP é um projeto de demonstração independente contendo a nova sala e todos os seus recursos. Pode ser extraído em uma pasta separada e aberto pelo `project.godot` que pertence à demonstração.

Para adicionar ao projeto existente, copie apenas as pastas `scenes/dungeon`, `assets/generated/dungeon_central`, `tools/dungeon_central` e `docs/dungeon_central`, preservando os caminhos. Não copie o project.godot da demonstração sobre o project.godot original. A instalação direta efetuada nesta tarefa copia somente arquivos novos e verifica previamente que seus nomes não existem.

## Regiões do atlas

Formato: [coluna, linha, largura em células, altura em células]. A unidade é 16 px. Dimensão nativa informa os pixels antes de adicionar margens transparentes, nunca redimensionados.

| Peça | Região no atlas novo | Dimensão nativa | Origem |
|---|---|---|---|
| parede_frontal | [0, 0, 4, 6] | [64, 88] | C |
| coluna_moldura | [5, 0, 2, 6] | [32, 88] | C |
| parede_desce | [8, 0, 5, 10] | [69, 150] | C |
| parede_sobe | [14, 0, 5, 10] | [69, 150] | C |
| porta_frontal | [20, 0, 10, 10] | [154, 157] | C |
| porta_sobe | [31, 0, 6, 12] | [92, 179] | C |
| porta_desce | [38, 0, 6, 12] | [92, 179] | C |
| pilar | [45, 0, 4, 8] | [52, 115] | C |
| grade_central | [50, 0, 8, 8] | [113, 117] | C |
| tocha | [59, 0, 2, 5] | [30, 79] | C |
| entulho_a | [0, 13, 4, 4] | [62, 60] | C |
| entulho_b | [5, 13, 4, 4] | [52, 53] | C |
| tijolos | [10, 13, 5, 4] | [72, 56] | C |
| pedra | [16, 13, 3, 3] | [34, 33] | C |
| teia | [20, 13, 5, 5] | [73, 75] | A |
| respiro_original | [26, 13, 2, 2] | [32, 32] | original |
| parede_sobe_curta | [29, 13, 1, 10] | [16, 160] | native_module_slice |
| parede_desce_curta | [31, 13, 1, 10] | [16, 160] | native_module_slice |
| parede_frontal_meia | [33, 13, 2, 6] | [32, 96] | native_module_slice |
| terra_0 | [36, 13, 1, 1] | [16, 16] | C |
| terra_1 | [38, 13, 1, 1] | [16, 16] | C |
| terra_2 | [40, 13, 1, 1] | [16, 16] | C |
| terra_3 | [42, 13, 1, 1] | [16, 16] | C |
| terra_4 | [44, 13, 1, 1] | [16, 16] | C |
| terra_5 | [46, 13, 1, 1] | [16, 16] | C |
| terra_6 | [48, 13, 1, 1] | [16, 16] | C |
| terra_7 | [50, 13, 1, 1] | [16, 16] | C |
| terra_8 | [52, 13, 1, 1] | [16, 16] | C |
| terra_9 | [54, 13, 1, 1] | [16, 16] | C |
| terra_10 | [56, 13, 1, 1] | [16, 16] | C |
| terra_11 | [58, 13, 1, 1] | [16, 16] | C |
| terra_12 | [60, 13, 1, 1] | [16, 16] | C |
| terra_13 | [62, 13, 1, 1] | [16, 16] | C |
| terra_14 | [0, 24, 1, 1] | [16, 16] | C |
| terra_15 | [2, 24, 1, 1] | [16, 16] | C |
| piso_tunel | [4, 24, 1, 1] | [16, 16] | darkened_native_soil |
| lajes_0 | [6, 24, 4, 4] | [64, 64] | C |
| lajes_1 | [11, 24, 4, 4] | [64, 64] | C |
| lajes_2 | [16, 24, 4, 4] | [64, 64] | C |
| lajes_3 | [21, 24, 4, 4] | [64, 64] | C |
| lajes_4 | [26, 24, 4, 4] | [64, 64] | C |
| lajes_5 | [31, 24, 4, 4] | [64, 64] | C |
| lajes_6 | [36, 24, 4, 4] | [64, 64] | C |
| lajes_7 | [41, 24, 4, 4] | [64, 64] | C |
| lateral_meio | [46, 24, 2, 1] | [28, 16] | C |
| lateral_topo | [49, 24, 2, 2] | [32, 31] | C |
| sombra_pilar | [52, 24, 5, 2] | [80, 32] | procedural_shadow |
