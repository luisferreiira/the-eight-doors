# Proposta de expansão do labirinto

**Proposta para aprovação.** O mapa passa de **6 para 30 salas**, com 24 novas salas e oito posições de porta por sala. S01 continua sendo a referência de início e a saída existente permanece ao sul de S04.

São **6 ligações preservadas**, **44 ligações novas** (40 abertas e 4 trancadas), **4 novos desafios em 8 faces de porta** e **139 portas permanentemente seladas**. A porta sul de S04 é contabilizada separadamente como saída.

## Mapa atual e ligações preservadas

O código em `scripts/world/mapa.gd` usa coordenadas inteiras, destinos por direção em `links` e IDs compartilhados entre as faces trancadas em `seals`. Porta sem destino não atravessa. Com destino, ela abre se estiver sem selo ou se o selo tiver sido resolvido. O catálogo atual registra S01 a S06.

| Sala | Coordenada | Abertas hoje | Trancadas hoje | Sem passagem hoje |
|---|---|---|---|---|
| S01 | (0, 0) | N → S02, NE → S03, S → S05, SO → S06 | L → S04 | SE, O, NO |
| S02 | (0, -1) | S → S01 | — | N, NE, L, SE, SO, O, NO |
| S03 | (1, -1) | SO → S01, S → S04 | — | N, NE, L, SE, O, NO |
| S04 | (1, 0) | N → S03 | O → S01 | NE, L, SE, SO, NO · S é a saída |
| S05 | (0, 1) | N → S01 | — | NE, L, SE, S, SO, O, NO |
| S06 | (-1, 1) | NE → S01 | — | N, L, SE, S, SO, O, NO |

O **E0 — Ciclo da Luz** continua em S01 L ↔ S04 O. A sequência atual é **Estrela → Lua → Sol**. A rota livre S01 → S03 → S04 permanece disponível.

## Novas ligações e desafios

Cada ligação é bidirecional. As portas indicadas são opostas e os destinos são adjacentes nas coordenadas do esboço.

| Origem e porta | Destino e porta | Estado proposto |
|---|---|---|
| S01 NO | S07 SE | Aberta |
| S01 O | S10 L | Aberta |
| S02 O | S07 L | Aberta |
| S02 N | S15 S | Aberta |
| S03 N | S16 S | Aberta |
| S03 L | S18 O | Aberta |
| S04 L | S23 O | Aberta |
| S05 SE | S28 NO | Aberta |
| S05 S | S29 N | Aberta |
| S06 N | S10 S | Aberta |
| S06 O | S11 L | Aberta |
| S06 S | S30 N | D4 |
| S07 O | S08 L | Aberta |
| S07 S | S10 N | Aberta |
| S08 S | S09 N | Aberta |
| S08 SO | S13 NE | Aberta |
| S08 O | S14 L | D1 |
| S09 L | S10 O | Aberta |
| S09 S | S11 N | Aberta |
| S09 O | S13 L | Aberta |
| S11 O | S12 L | Aberta |
| S11 SE | S30 NO | Aberta |
| S12 N | S13 S | Aberta |
| S13 N | S14 S | Aberta |
| S15 L | S16 O | Aberta |
| S16 L | S17 O | Aberta |
| S16 N | S22 S | Aberta |
| S17 S | S18 N | Aberta |
| S17 L | S20 O | D2 |
| S18 L | S19 O | Aberta |
| S18 S | S23 N | Aberta |
| S19 N | S20 S | Aberta |
| S19 S | S24 N | Aberta |
| S20 N | S21 S | Aberta |
| S23 L | S24 O | Aberta |
| S23 S | S26 N | D3 |
| S24 S | S25 N | Aberta |
| S24 SO | S26 NE | Aberta |
| S25 O | S26 L | Aberta |
| S25 SO | S27 NE | Aberta |
| S26 S | S27 N | Aberta |
| S27 O | S28 L | Aberta |
| S28 O | S29 L | Aberta |
| S29 O | S30 L | Aberta |

| Desafio | Passagem | Pista acessível | Condição |
|---|---|---|---|
| D1 | S08 ↔ S14 | S13 | Copiar a sequência de marcas gravadas em S13. |
| D2 | S17 ↔ S20 | S19 | Ajustar três discos conforme o relevo em S19. |
| D3 | S23 ↔ S26 | S24 | Reproduzir o padrão de luzes observado em S24. |
| D4 | S06 ↔ S30 | S29 | Ler a inscrição de S29 e selecionar o símbolo correspondente. |

Cada painel deve poder ser acionado de ambos os lados da sua passagem. As pistas ficam na rede aberta, podem ser consultadas em qualquer ordem e o desbloqueio vale para as duas faces.

## Coordenadas e portas que ficam seladas

| Sala | Coordenada | Portas permanentemente seladas |
|---|---|---|
| S01 | (0, 0) | SE |
| S02 | (0, -1) | NE, L, SE, SO, NO |
| S03 | (1, -1) | NE, SE, O, NO |
| S04 | (1, 0) | NE, SE, SO, NO |
| S05 | (0, 1) | NE, L, SO, O, NO |
| S06 | (-1, 1) | L, SE, SO, NO |
| S07 | (-1, -1) | N, NE, SO, NO |
| S08 | (-2, -1) | N, NE, SE, NO |
| S09 | (-2, 0) | NE, SE, SO, NO |
| S10 | (-1, 0) | NE, SE, SO, NO |
| S11 | (-2, 1) | NE, S, SO, NO |
| S12 | (-3, 1) | NE, SE, S, SO, O, NO |
| S13 | (-3, 0) | SE, SO, O, NO |
| S14 | (-3, -1) | N, NE, SE, SO, O, NO |
| S15 | (0, -2) | N, NE, SE, SO, O, NO |
| S16 | (1, -2) | NE, SE, SO, NO |
| S17 | (2, -2) | N, NE, SE, SO, NO |
| S18 | (2, -1) | NE, SE, SO, NO |
| S19 | (3, -1) | NE, L, SE, SO, NO |
| S20 | (3, -2) | NE, L, SE, SO, NO |
| S21 | (3, -3) | N, NE, L, SE, SO, O, NO |
| S22 | (1, -3) | N, NE, L, SE, SO, O, NO |
| S23 | (2, 0) | NE, SE, SO, NO |
| S24 | (3, 0) | NE, L, SE, NO |
| S25 | (3, 1) | NE, L, SE, S, NO |
| S26 | (2, 1) | SE, SO, O, NO |
| S27 | (2, 2) | L, SE, S, SO, NO |
| S28 | (1, 2) | N, NE, SE, S, SO |
| S29 | (0, 2) | NE, SE, S, SO, NO |
| S30 | (-1, 2) | NE, SE, S, SO, O |

## Progressão e limites

- A rede aberta alcança todas as 30 salas e a saída, mesmo com os cinco selos fechados.
- Exemplos de voltas abertas: S01 → S02 → S07 → S08 → S09 → S10 → S01 e S01 → S03 → S04 → S23 → S24 → S25 → S26 → S27 → S28 → S29 → S05 → S01.
- S21 e S22 são becos sem saída. S14 vira um atalho quando D1 é resolvido.
- A revisão acrescenta 12 ligações abertas ao primeiro esboço, seis delas diagonais. S18–S23 e S19–S24 ligam diretamente o norte ao leste. S11–S30 liga oeste e sul. A rede aberta tem 16 ciclos independentes, contra 4 no primeiro esboço.
- O esboço usa o passo físico e os portais do mapa. A validação considera a geometria padrão das salas. Na implementação, decoração e obstáculos ainda devem respeitar os envelopes e manter os portais livres.
- Aprovar a distribuição das salas, a posição dos quatro atalhos e o conteúdo das pistas antes de implementar. Nenhuma condição nova é obrigatória para escapar.
