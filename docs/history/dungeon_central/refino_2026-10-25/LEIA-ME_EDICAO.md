# Sala central refinada — edição manual preservada

Cena: `res://scenes/dungeon/sala_central_referencia.tscn`.
Backup anterior a esta correção: `backups/refino_sala_central_2026-10-25_11964424/`.

## O que foi identificado

- O piso tinha células de terra fora do contorno, formando degraus externos.
- As estampas diagonais tinham faces com alturas diferentes da alvenaria reta. Fatias estreitas dessas peças criavam pontas nos cantos e bases salientes.
- Parte da parede reta havia sido pintada manualmente com o atlas C. Essas 132 células foram preservadas.
- Paredes e manchas de laje eram estampas de várias células: apagar a célula de origem removia um objeto inteiro. Colunas, luzes e decorações também estavam combinadas em TileMapLayers, dificultando mover um objeto com seus componentes.
- Os nós não tinham travas explícitas. O problema principal de edição estava na granularidade das estampas e na falta de objetos independentes.
- O gerador opcional antigo salvava por cima da cena. Ele não estava associado à execução da sala, mas sua execução manual poderia apagar alterações do editor.

## Etapa A — muro-base

As faces diagonais foram regularizadas para usar capeamento de 16 px, alvenaria de 64 px e rodapé de 8 px. A inclinação é contínua; a textura original não foi esticada. Um complemento pequeno foi composto com texels dos próprios assets. Foram substituídas 20 estampas diagonais problemáticas, mantendo a alvenaria reta e as oito aberturas.

As oito peças antigas de canto, que duplicavam a estrutura e produziam saliências, foram retiradas depois que a base passou a se conectar diretamente. O acabamento das entradas foi separado em Molduras. Não foram usadas tochas, colunas ou teias para disfarçar a geometria.

O piso foi limitado ao encontro real com a parede. As poucas células cortadas na borda usam variantes transparentes de 16×16, sem shader de recorte e sem geração em runtime. O teste encontrou zero pixels de terra fora do perímetro definido. `02_muro_base.png` é a captura real dessa etapa sem decoração.

## Etapa B — piso e acabamento

Foram mantidos os agrupamentos existentes e acrescentadas 56 posições de manchas com oito variações de lajes. As células de pedra passaram de 339 para 905. A área visível da camada aumentou de 70.144 para 192.237 pixels (2,74 vezes), cobrindo aproximadamente 30,5% do piso; a terra continua predominante.

O centro em torno da grade permanece livre. Os 17 objetos de pedras e tijolos mantiveram posição e escala. As quatro colunas e a grade central conservaram suas posições visuais. As tochas diagonais foram alinhadas às faces regulares do muro, com a luz acompanhando cada objeto. As teias foram reduzidas de oito para quatro e presas às paredes retas, evitando redes soltas sobre o piso.

As descidas Leste/Oeste continuam com interior escuro e escadas. Seus apoios de pedra agora usam blocos maiores, em vez de repetir uma faixa de capeamento a cada 16 px.

## Como editar na Godot

1. Se a cena já estiver aberta durante uma alteração externa, recarregue a versão do disco antes de salvar a aba antiga.
2. Para pintar ou apagar, selecione Piso, TransicoesPiso, Paredes, Molduras, Tunel ou Portas. As células pintadas têm unidade real de 16×16. No TileSet, use a fonte **Pecas editaveis 16x16** para fragmentos originais, **Muro diagonal regular 16x16** para o muro novo e **Bordas de terra 16x16** nas bordas do chão. As fontes anteriores continuam disponíveis.
3. Para mover uma coluna, selecione `Elementos/Colunas/ColunaNO`, `ColunaNE`, `ColunaSO` ou `ColunaSE`. A sombra, o visual e a base física são filhos e acompanham esse nó. A posição do nó fica no pé da coluna, adequado para ordenação por profundidade.
4. Cada grupo em `Elementos/Tochas` contém o sprite e a luz. Mova esse grupo para que ambos acompanhem a edição.
5. A grade central está em `Elementos/GradeCentral`. Teias e respiros têm nós próprios. As pedras e tijolos estão como sprites nomeados dentro de Entulho.
6. Todos esses nós pertencem diretamente à cena, sem instâncias herdadas e sem travas de edição. Não há escala artificial nos sprites. Cada objeto decorativo corresponde a um objeto, e não a um nó por bloco de parede.
7. A câmera tem a opção **Enquadramento Automatico** no Inspector. Desmarque-a para manter sua posição e zoom manuais. A área de enquadramento também pode ser editada.

Entulho, Elementos e SombrasElementos mantiveram os nomes e os nós anteriores. Seus objetos foram separados em filhos selecionáveis. SombrasElementos fica disponível para pintura manual adicional; as sombras dos quatro pilares agora acompanham cada coluna.

## Proteção das edições

Não há script de construção associado à sala. Os scripts temporários usados no refinamento não fazem parte do projeto entregue. O único script da cena é o enquadramento opcional da câmera.

`tools/dungeon_central/montar_cena.gd` agora encerra sem gravar se a cena já existir. O teste executou esse gerador e comparou o hash antes/depois: a cena permaneceu idêntica. Isso impede a ferramenta antiga de substituir alterações manuais. O editor continua livre para salvar suas edições normalmente.

## Organização atual

```
SalaCentralReferencia
  Fundo
  Piso / TransicoesPiso / Tunel / Paredes / Molduras / Portas  (TileMapLayer 16x16)
  Entulho  (17 sprites independentes)
  SombrasElementos  (camada livre)
  Elementos
    Colunas  (4 StaticBody2D, cada um com Visual, Sombra e BasePilar)
    Tochas   (8 grupos, cada um com Visual e PointLight2D)
    Teias    (4 sprites)
    Respiros (2 sprites)
    GradeCentral
  Colisoes (paredes e bases das molduras)
  Entradas (8 marcadores preservados)
  Iluminacao (ambiente)
  Camera2D
```

## Recursos e arquivos

Modificados:
- `scenes/dungeon/sala_central_referencia.tscn`.
- `scripts/camera/camera_sala_central.gd`: enquadramento opcional e editável.
- `tools/dungeon_central/montar_cena.gd`: proteção contra sobrescrita.
- `tools/dungeon_central/validar_cena.gd`: verificação da cena editável e da circulação.

Novos, em `assets/generated/dungeon_central/refino/`:
- `muro_diagonal_16.png`: 160×160 RGBA, duas faces diagonais e um apoio lateral; células de 16×16. Coordenadas em `muro_diagonal_manifesto.json`.
- `bordas_piso_16.png`: 256×48 RGBA, 43 variantes de borda cortadas em células de 16×16.
- Arquivos de importação desses PNGs.

Os atlas anteriores, o TileSet externo anterior, personagens, controles, `scenes/world/environments/fase_caverna.tscn` e `project.godot` não foram modificados. A cena usa seu TileSet local com fontes adicionais; as fontes originais foram conservadas. Não foi criado um fundo com a imagem de referência.

## Colisões e validação

As posições mundiais das colisões foram conservadas. As quatro bases dos pilares mudaram apenas de pai: agora acompanham as colunas. As paredes e as quatro bases das molduras continuam em Colisoes. Os 24 polígonos totais mantêm a solidez das bases e deixam os oito vãos livres.

A cena foi carregada e executada na Godot 4.7.1 oficial, renderer OpenGL Compatibility. Foram verificadas referências, regiões dentro dos atlas, grade, células unitárias, owners, ausência de instâncias/travas, colisões e rotas para as oito saídas com diâmetros de 16 e 32 px. O teste também pintou um tile, apagou outro, moveu uma coluna e mudou a câmera em uma cópia: salvou, reabriu e executou quadros, confirmando que todas as edições permaneceram. Isso foi feito pela API nativa, sem simular cliques manuais no editor.

O resultado está em `validacao_godot.json`, sem falhas. `01_antes.png`, `02_muro_base.png` e `03_final_godot.png` são capturas reais. Os números do piso estão em `comparacao_piso.json`.

## Limitações

O projeto inspecionado ainda não contém um jogador integrado a esta sala. A circulação foi verificada com corpos de teste, sem alterar gameplay. Ao adicionar o jogador, escolha sua ordenação por profundidade junto às colunas e molduras e verifique seu raio real.

As chamas continuam estáticas e as luzes não possuem sombras dinâmicas de parede. A arte foi ajustada com os recursos disponíveis, mantendo os texels nativos, sem pretender reproduzir a referência pixel a pixel.
