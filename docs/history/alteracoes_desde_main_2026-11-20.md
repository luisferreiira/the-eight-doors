# Alterações desde a main — 20 de novembro de 2026

A comparação usa a `origin/main` em `82c8be71c6e9f347b9bcd0d87f293eafa029e9ae`. Antes deste salvamento, a branch `feat/ambiente-de-implementacao` apontava para o mesmo commit. A versão local acrescenta 13 arquivos e modifica 15, além deste relatório.

## O que mudou na partida

- **Abertura.** Depois da escolha de Aelin ou Dorian, o jogo apresenta a história antes de entrar no labirinto. Os quadros têm controles para voltar, avançar e pular, transições e trechos de texto que acompanham o personagem escolhido.
- **Fuga e derrota.** Escapar por qualquer uma das duas saídas apresenta o desfecho de fuga. Perder a última vida apresenta o desfecho de derrota. Ao concluir ou pular a narrativa, o jogador vê o placar com o foco em reiniciar.
- **Cenas narrativas.** A abertura e os dois desfechos têm cenas editáveis em `scenes/ui/historia/`, com uma cena e um script compartilhados para navegação. A arte inclui um shader de placa e um ícone para pular.
- **Enigmas e pausa.** O tema de inscrição e as cenas D3, D7, D8 e D9 receberam ajustes visuais. A tela de pausa ganhou uma placa com arte própria para o botão de menu inicial.
- **Atmosfera.** A vinheta do labirinto passou de 0,4 para 0,8 de intensidade, com ajustes de raio e suavidade para reforçar as bordas.

## Documentação e testes

O novo [documento de design](../planejamento/GDD.md) reúne a história, o fluxo da partida, as mecânicas e a direção de arte e som. Os testes de integração dos menus, do labirinto e de pontuação e vidas foram adaptados ao fluxo narrativo.

Os resultados abaixo vêm dos arquivos JSON presentes na versão local antes da publicação. Os testes não foram executados novamente para este salvamento.

- O registro funcional da cena principal mantém a lista de falhas vazia e atualiza uma medição de deslocamento.
- O registro de integração dos menus informa 101 verificações e quatro ocorrências de falha. “Pausa interrompeu fade” e “Travessia não concluiu” aparecem duas vezes cada. A reprodução dessas falhas na versão publicada permanece pendente.
