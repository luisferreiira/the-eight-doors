# The Eight Doors

**The Eight Doors** é um jogo 2D *top-down* de fantasia medieval, exploração e enigmas (*escape room*), desenvolvido na **Godot 4** com gráficos em pixel art.

## Sobre o jogo

Preso em um misterioso labirinto mágico, o jogador precisa explorar salas, interpretar pistas, resolver enigmas e encontrar uma saída. Antes de iniciar a exploração, o jogador escolhe entre **Aelin** e **Dorian**. A narrativa de fuga, as pistas e os enigmas ainda fazem parte do planejamento.

O labirinto tem um **mapa fixo e espacialmente coerente**: cada sala é octogonal e possui **oito portas**, correspondentes às direções norte, nordeste, leste, sudeste, sul, sudoeste, oeste e noroeste. Nem todas as portas estão abertas. Uma passagem para o norte, por exemplo, leva à sala posicionada ao norte, com entrada pela porta sul.

O objetivo planejado é escapar do labirinto cumprindo requisitos de exploração e enigmas; a versão atual ainda não possui saídas de vitória. A proposta também inclui salas com efeitos mágicos e um mapa de consulta que não revela automaticamente a posição do jogador. Os pontos de entrada seguros já fazem parte do protótipo.

## Como funciona

- **WASD:** movimentação em oito direções.
- **Portas abertas:** passagem automática para a sala conectada.
- **Portas seladas:** bloqueiam as direções sem conexão no mapa atual; o desbloqueio por enigmas ainda não está implementado.
- **Esc:** abre e fecha a pausa durante a exploração. O menu de pausa permite retomar ou reiniciar a partida com o mesmo personagem.
- **Áudio:** música, som dos botões e controle de volume nas telas de menu e seleção.
- **Exploração:** percorra as seis salas conectadas; ainda não há uma condição de fuga ou vitória.
- **Interação com E, enigmas, pistas e diário:** mecânicas planejadas para as próximas etapas.

## Estado atual do desenvolvimento

O projeto está em fase de **protótipo jogável**. O repositório contém as seguintes funcionalidades implementadas:

- Uma **sala octogonal reutilizável** com oito posições de porta.
- Uma rede inicial de **seis salas (S01–S06)**, com cinco conexões bidirecionais a partir de S01.
- Posicionamento espacial coerente e entrada pela porta oposta à de saída.
- Portas abertas e seladas, com colisões e validações de travessia.
- Transições automáticas entre salas e proteção contra retorno imediato.
- Menu inicial e seleção de **Aelin ou Dorian**, integrada ao início da exploração.
- Personagens com movimentação funcional, colisões e animações de caminhada e parada.
- Pausa, retomada e reinício da partida com o personagem selecionado.
- Música, efeitos sonoros dos botões e controle de volume nos menus.
- Câmera que acompanha o personagem, atmosfera visual e pontos de entrada seguros.
- Scripts de testes automatizados das conexões, travessias, colisões e integração dos menus.

Atualmente, o foco é consolidar os sistemas de exploração antes de ampliar o conteúdo.

## Próximas etapas

- Criar enigmas interativos e portas desbloqueáveis.
- Implementar pistas, diário e mapa de consulta do jogador.
- Adicionar vidas, pontuação e condições de vitória.
- Introduzir salas com efeitos mágicos e diferentes possibilidades de fuga.
- Expandir gradualmente o labirinto para **40 a 60 salas**.
- Refinar as animações e os efeitos visuais e sonoros.

## Executar o projeto

1. Clone o repositório:

   ```bash
   git clone https://github.com/luisferreiira/the-eight-doors.git
   ```
2. Abra a pasta do projeto na **Godot 4.7**, versão declarada no projeto (arquivo `project.godot`).
3. Execute a cena principal com **F5**.

> **Status:** projeto em desenvolvimento. Os recursos descritos em “Próximas etapas” representam o planejamento e ainda não devem ser considerados disponíveis na versão atual.
