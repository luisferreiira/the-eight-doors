# Distribuição dos nascimentos

Cada nova partida sorteia uma das três salas aprovadas, com **1/3 de chance para cada uma**:

| Ponto | Sala | Região |
|---|---|---|
| P1 | S22 | Norte |
| P2 | S23 | Leste |
| P3 | S29 | Sul |

S01 e as duas saídas não participam do sorteio. Reiniciar pelo menu de pausa ou pela vitória inicia um novo sorteio, mantendo o personagem escolhido e limpando o progresso dos desafios. Sorteios são independentes, portanto a mesma sala pode aparecer em partidas consecutivas.

## Editar os pontos

Abra `scenes/world/rooms/sala_s22.tscn`, `sala_s23.tscn` ou `sala_s29.tscn` no editor 2D e mova o **Marker2D Nascimento**. Ele também aparece nas instâncias da visão geral. Edite a cena individual para aplicar a posição ao jogo.

Os três marcadores começam em `(560, 640)` no espaço local de cada sala, com posições globais distintas no mapa. Estão longe das portas e têm área livre ao redor. Travessias entre salas continuam chegando no marcador da porta oposta, não no ponto de nascimento.

Em `labirinto.tscn`, **Random Spawn** está habilitado por padrão. Desative-o para testes fixos na S01. **Spawn Seed = 0** faz um sorteio novo; uma semente não zero reproduz a mesma escolha para depuração.

Esta etapa não acrescenta dicas nem efeitos. As salas de início estão marcadas como seguras para a futura implementação desses sistemas.

## Verificação

`tests/test_nascimentos.gd` cobre os três inícios com ambos os personagens, colisões no ponto e nos arredores, ausência de gatilhos de porta, repetibilidade da semente, modo fixo de teste e preservação da chegada por portas. Em 3.000 sementes: S22 = 971, S23 = 998 e S29 = 1.031.
