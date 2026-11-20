# The Eight Doors — Game Design Document

Versão 0.2 · Rascunho para revisão da dupla

**Curso** — Bacharelado em Sistemas de Informação  
**Disciplina** — Fundamentos de Desenvolvimento de Jogos  
**Professor** — Fábio Corsini  
**Equipe** — Starplay -- Luís Ferreira ★ e Maria Cecília Santos

## Visão do jogo

The Eight Doors é um jogo 2D de exploração e enigmas, com visão de cima, fantasia medieval e pixel art. O jogador escolhe Aelin ou Dorian, explora livremente uma caverna de salas octogonais e pode encontrar pistas de direção em algumas salas. A fuga revela o que aconteceu com o personagem e como terminou a guerra que ele foi investigar.

**Objetivo do jogador** — Encontre uma saída da caverna antes que suas vidas acabem.

## Gênero

Aventura de exploração e quebra-cabeças para um jogador, com visão de cima.

## Público-alvo

Jogadores que gostam de explorar labirintos, interpretar pistas e resolver enigmas de orientação em jogos de fantasia.

## Plataforma do jogo

Desenvolvimento na Godot. Computador com teclado como plataforma de referência para o protótipo.

## Experiência e fluxo da partida

**Fluxo da partida** — Menu inicial → seleção → abertura → Sala de Nascimento → exploração → cena de fuga ou de derrota → resultado. Na fuga, o desfecho termina com **FIM**. Reiniciar começa uma nova partida com o mesmo personagem e faz um novo sorteio do ponto de início.

Durante a exploração, o jogador atravessa portas, encontra inscrições, resolve desafios para abrir passagens e procura uma saída. O objetivo apresentado no início é encontrar uma saída da caverna. A investigação dá contexto à exploração. A revelação fica no desfecho, sem cenas narrativas durante a partida.

## História

### Abertura

1. Antes da guerra, o rei mandou abrir oito portas sob a capital. Delas saíram criaturas sem corpo, capazes de possuir os vivos e usar suas vozes e sua magia. A guerra começou naquela noite. Quando os ataques cessaram, o castelo anunciou que as portas haviam sido fechadas e que as criaturas tinham sido devolvidas ao seu mundo.

2. Dorian encontra na biblioteca a ordem assinada pelo pai para abrir as portas. Aelin, contratada sob um nome falso para fazer desaparecer documentos que ligam o rei à guerra, encontra os nomes dos pais numa lista da última noite. Os documentos levam ambos aos túneis do castelo.

3. O personagem escreve no caderno a promessa *Se eu descobrir o que aconteceu, vou contar* e marca o caminho de volta enquanto desce. Na caverna, encontra uma inscrição datada da última noite da guerra e começa a copiá-la. Tudo fica escuro. A exploração começa quando o personagem abre os olhos numa sala desconhecida.

### Vitória em qualquer uma das saídas

1. O personagem abre os olhos no chão da caverna real e encontra o lápis com a ponta gasta. No caderno, há uma página inteira em sua letra, embora só se lembre de ter escrito a data.

2. A inscrição revela que o rei queria uma magia capaz de controlar a vontade das pessoas. Na última noite, os pais de Aelin lançaram um feitiço que fechou as oito passagens. O esforço consumiu suas forças, e eles foram arrastados para o outro lado antes de a última porta fechar. A magia se dissipou aos poucos.

3. O personagem se lembra da mão escrevendo contra sua vontade e entende que a caverna explorada foi feita com suas lembranças. Ao escapar, recupera o controle do corpo. Dorian promete expor o que o pai fez e tirá-lo do trono. Aelin lê os nomes dos pais na inscrição e promete derrubar o rei por eles.

4. Perto da superfície, o personagem abre o caderno. Uma letra desconhecida aparece traço por traço: *Nunca partimos. Nosso retorno está próximo.* Surge **FIM**.

A última mensagem é a primeira confirmação de que as criaturas permaneceram no mundo mortal.

### Derrota · Seu próprio nome

Ao perder a última vida, o personagem tenta dizer o próprio nome, mas acaba ouvindo a sua voz vinda do escuro. O desfecho termina com a promessa que ele escreveu no caderno antes de descer. Em seguida, o resultado oferece jogar de novo ou voltar ao menu.

## O mundo do jogo

A caverna fica sob a capital, perto das oito portas abertas no início da guerra. O espaço explorado durante a partida é uma reconstrução mental da caverna real. As salas octogonais usam a rosa dos ventos para orientar a exploração. Aelin e Dorian têm a mesma movimentação e enfrentam os mesmos desafios.

## Combate

O jogo é de exploração e enigmas, sem sistema de combate. A ameaça à sobrevivência durante a partida vem das quedas e dos erros acumulados nos desafios. Vencer a criatura significa escapar do labirinto e recuperar o controle do corpo.

## Mecânicas no projeto

| Sistema | Funcionamento atual |
| --- | --- |
| Movimento e interação | WASD, com diagonais, e E para examinar inscrições ou escapar junto à saída. |
| Salas | 30 cenas de sala. Mapa fixo, com oito posições de porta por sala octogonal. Portas de passagem usam as direções da rosa dos ventos. |
| Nascimento | A partida sorteia uma entre S22, S23 e S29. |
| Saídas | S14 a oeste e S21 ao norte. A interação junto ao marcador conclui a partida. |
| Desafios | Um enigma de sequência de pedras e quatro de direção. Resolver um desafio abre a passagem. A cada três erros no mesmo desafio, perde-se uma vida. |
| Pontuação e vidas | Três vidas iniciais. Quedas custam uma vida. Cada desafio rende 300, 200 ou 100 pontos, conforme os erros. A fuga rende 500 pontos mais 100 por vida restante. |
| Transições | O jogador passa do menu à seleção e da abertura ao labirinto. As travessias entre salas têm fade. A fuga e a perda da última vida abrem cenas narrativas antes do resultado. |
| Interface | Menu inicial, escolha de personagem, HUD de vidas e pontos, pergaminho contextual, painéis de enigma, pausa e tela de resultado. |

Os desafios de direção dão ao jogador uma tarefa concreta de orientação. O significado do percurso muda quando o final revela a prisão mental. As inscrições e dicas ajudam na exploração.

## Arte, som e cenas narrativas

A direção visual usa pixel art, uma caverna escura e elementos medievais. A abertura, a fuga e a derrota ocupam a tela inteira e são cenas `.tscn` editáveis no editor 2D da Godot. Os quadros usam fundo preto, títulos em placas de pedra e texto em tom de inscrição antiga. Na fuga, a última frase aparece aos poucos, seguida de **FIM**. O jogador pode avançar pelo ícone no canto inferior direito ou pular a cena pelo ícone no canto superior direito.

## Decisões para fechar o documento

- **Entrega:** confirmar nomes da dupla, prazo, plataforma alvo e detalhes do modelo disponibilizado no GSA.
- **Artigo-base:** obter o artigo citado no enunciado e registrar sua referência e como ele fundamenta o jogo.
- **Escopo:** confirmar se a entrega usa as 30 salas atuais e quais recursos de mapa ou orientação entram nesta versão.
- **Apresentação:** revisar o ritmo de leitura, a arte e a trilha das telas narrativas.

## Entrega e avaliação da disciplina

- Link para o [repositório do jogo](https://github.com/luisferreiira/the-eight-doors).
- Documento do GDD conforme o modelo apresentado no GSA.
- Slides para a apresentação em sala de aula.
- Vídeo de apresentação para os avaliadores externos.

| Critério | Peso |
| --- | ---: |
| Itens solicitados | 10% |
| Apresentação do projeto | 10% |
| Aceite pelos avaliadores | 20% |
| Jogo funcionando sem bugs evidentes e coerente com o GDD e os requisitos mínimos | 60% |

Antes da entrega, a dupla deve verificar o percurso da seleção ao labirinto, as transições entre salas, a vitória nas duas saídas, a derrota com zero vidas e o cálculo da pontuação final.

## Referências

- CORSINI, Fábio. *Semana 02: Fundamentos de Desenvolvimento de Jogos Digitais*. Slide 19, tópicos necessários do GDD.
- ROGERS, Scott. *Level Up: um guia para o design de grandes jogos*. São Paulo: Blucher, 2012. Referência indicada nos slides da disciplina.
- MAAS, Sarah J. *Trono de Vidro*. Referência atmosférica de fantasia e possessão.
- Artigo-base do projeto final. Dados bibliográficos a preencher quando o artigo for identificado.

- [Visão geral e propostas anteriores](VISAO_GERAL.md)
- [Distribuição dos nascimentos](nascimentos.md)
- [Mapa e saídas no código](../../scripts/world/mapa.gd)
- [Interação, pontuação e resultado no código](../../scripts/world/labirinto.gd)
- [Cenas dos enigmas de direção](../../scenes/ui/gameplay/enigmas)
