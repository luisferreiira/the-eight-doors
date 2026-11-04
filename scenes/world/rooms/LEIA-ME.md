# Edição visual das salas

Abra sala_s01.tscn até sala_s06.tscn no editor 2D. São cenas herdadas de
../labirinto/sala_octogonal_base.tscn: piso, paredes, portas e iluminação aparecem
na árvore de nós. Alterações na base continuam sendo compartilhadas.

Para conteúdo exclusivo, adicione nós em ConteudoDaSala/Decoracao,
ConteudoDaSala/Obstaculos ou ConteudoDaSala/Interacoes. Obstáculos sólidos precisam
de StaticBody2D e CollisionShape2D/CollisionPolygon2D, na camada de colisão 1.
As propriedades sobrescritas em uma sala pertencem somente àquela cena.
Ao editar recursos compartilhados como TileSet, torne o recurso único antes
de alterar sua definição se a alteração não deve afetar outras salas.

O mapa_editor.tscn continua sendo uma visão geral: use Atualizar mapa depois de
salvar as salas. Faça as edições nas cenas individuais, pois a visão geral é
reconstruída pelo script.

Execute o projeto (F5) para jogar. As salas individuais são cenários; o jogador,
a câmera e as conexões são configurados pelo gerenciador labirinto.gd.

Para expandir, crie uma nova cena herdada da base, salve nesta pasta, registre
seu ID em cenas_salas.gd e configure as conexões de ida e volta em mapa.gd.
O formato octogonal, limites da câmera e posições dos portais ainda seguem
mapa.gd; mudar a geometria exige também atualizar esses dados e as colisões.
