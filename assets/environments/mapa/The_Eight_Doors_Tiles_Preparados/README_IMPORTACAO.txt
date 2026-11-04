THE EIGHT DOORS — ATLAS COMPLEMENTARES PREPARADOS
Godot Engine 4.7.1

CONTEÚDO
- atlas_complementar_A.png
- atlas_complementar_B.png
- preview_transparencia.jpg
- atlas_info.json

IMPORTANTE: ESTES SÃO ATLAS GRÁFICOS GERADOS POR IA, NÃO TILESETS VALIDADO/PRONTO.
As imagens foram preservadas em 1536x1024 RGBA, com tratamento leve dos pixels de alpha quase zero.
A grade-base 16x16 é apenas uma referência de trabalho porque o pacote original mainlevbuild.png usa 16x16, mas a arte gerada não foi desenhada com alinhamento matemático garantido em todas as peças.
Não redimensione as imagens e não substitua os atlas originais.

IMPORTAÇÃO SEGURA NO GODOT
1. Faça backup do projeto.
2. Copie os PNGs para uma pasta separada, por exemplo res://assets/tiles_generated/.
3. Selecione um PNG e confira Import > Compress > Lossless e Filter/Texture Filter em Nearest (sem suavização).
4. Reimporte.
5. Abra o TileSet e adicione um Atlas Source para o PNG.
6. Use Texture Region Size 16x16 somente como grade inicial para inspeção. A imagem tem 1536x1024, divisível por 16 (96 colunas x 64 linhas), mas isso NÃO garante que cada sprite esteja perfeitamente contido em células.
7. Selecione regiões de múltiplas células para portas, paredes, pilares e grades. Confira visualmente cada região antes de usar no mapa.
8. Primeiro teste apenas uma parede e um trecho de piso em uma cena de teste. Não substitua fase_caverna.tscn até verificar o resultado.

LIMITAÇÕES CONHECIDAS
- Os sprites foram gerados como uma composição de atlas por IA, e nem todas as peças têm limites exatos de grade.
- Alguns elementos têm dimensões grandes e podem cruzar células.
- A transparência foi preservada e os pixels quase transparentes foram limpos, mas isso não garante que todos os contornos estejam perfeitos.
- Não foram configuradas colisões, terrains, occlusion, navigation ou um recurso .tres do TileSet.
- Nenhuma validação foi feita dentro do Godot nesta etapa.
- Não trate os PNGs como sprites modulares comprovadamente encaixáveis até testar as regiões selecionadas.

RECOMENDAÇÃO
Use estes atlas como fonte complementar de sprites, não como substitutos dos atlas originais. Se algum sprite estiver cortado pela grade ou tiver arte fundida com o fundo, não o use no mapa; prefira os recursos originais.
