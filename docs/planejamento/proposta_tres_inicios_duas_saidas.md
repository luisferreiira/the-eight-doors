# Três inícios seguros e duas saídas

Variante do [esboço de 30 salas e 50 ligações](esboco_expansao_mapa.svg). Mantém as coordenadas e as seis ligações do jogo atual. O esboço revisado tem 53 ligações internas, 45 abertas e oito com selo (E0 e D3 a D9). A escolha inicial proposta é um sorteio com chances iguais entre P1, P2 e P3. S01 continua no mapa como sala central.

- **P1 — S22**, no extremo norte.
- **P2 — S23**, no setor leste.
- **P3 — S29**, no setor sul.
- **Saída A — S14**, pela porta oeste.
- **Saída B — S21**, pela porta norte.

Nesta variante a porta sul de S04 fica selada. As duas novas saídas substituem a de S04 apenas no esboço. Elas não consomem ligações internas. O jogo continua com a saída atual de S04.

## Distâncias em travessias entre salas

Cada célula mostra o menor caminho **com todos os selos fechados / com todos abertos**. A interação final com a porta de saída não conta como travessia entre salas.

| Início | Sala | A · S14 | B · S21 |
|---|---|---:|---:|
| P1 | S22 | 8 / 7 | 6 / 6 |
| P2 | S23 | 8 / 7 | 6 / 6 |
| P3 | S29 | 6 / 6 | 7 / 7 |

Cada início alcança as duas saídas sem resolver desafios. Mesmo com todos os atalhos abertos, a menor distância até uma saída é de seis travessias. Os três inícios também ficam separados por pelo menos quatro travessias. De P1 e P2, a saída B fica mais perto. De P3, a saída A fica mais perto. S22 tem uma única passagem inicial até S16, de onde o jogador pode escolher a direção.

As três salas de nascimento devem ter uma área inicial sem inimigos, armadilhas ou dano imediato. A segurança é um requisito para a futura montagem das salas. O esboço permite aprovar os locais, as distâncias e o sorteio antes dessa etapa.

## Novas ligações com desafios

Cinco passagens da versão anterior ficam seladas. As pistas estão em salas acessíveis pela rede aberta e podem ser apresentadas como inscrições estáticas com respostas no painel existente.

| Selo | Ligação | Sala da pista | Desafio |
|---|---|---|---|
| D5 | S07–S09 | S08 | Reproduzir a ordem de três marcas de pedra. |
| D6 | S02–S16 | S15 | Ler a ordem das fases da lua na inscrição. |
| D7 | S03–S17 | S18 | Combinar os símbolos com os três relevos da parede. |
| D8 | S04–S26 | S24 | Ler três números e selecionar os símbolos correspondentes. |
| D9 | S25–S27 | S28 | Ordenar os símbolos pela altura dos três pedestais. |

## Revisão das ligações

- Passagens acrescentadas na revisão anterior: S02–S03, S02–S16, S03–S17, S04–S26, S05–S06, S05–S30, S06–S09, S07–S09, S07–S15 e S09–S12.
- Passagens abertas retiradas: S08–S13, S09–S13, S11–S30, S18–S23 e S19–S24.
- Atalhos propostos retirados: D1 (S08–S14) e D2 (S17–S20). D3 e D4 continuam opcionais.
- A aproximação final da saída A é S12 → S13 → S14. Para B, é S19 → S20 → S21.
