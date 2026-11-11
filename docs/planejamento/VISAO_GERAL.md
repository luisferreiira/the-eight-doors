# Visão geral — The Eight Doors

Referência de design: solicitação de auditoria de 04/11/2026. Estado técnico e evidências em [ESTADO_ATUAL.md](ESTADO_ATUAL.md); estimativas em [ROADMAP.md](ROADMAP.md).

## Conceito e decisões confirmadas

Jogo 2D top-down de fantasia medieval, mistério e exploração em pixel art, na Godot 4. O jogador está preso em um labirinto mágico e deverá descobrir pistas, resolver enigmas e cumprir os requisitos de uma saída. A inspiração atmosférica em Trono de Vidro deve evoluir para identidade narrativa própria.

- Aelin e Dorian têm aparências diferentes e as mesmas mecânicas na primeira versão. WASD, diagonais normalizadas, sem pulo nem gravidade. Refinamento artístico das animações está pausado.
- Mapa físico fixo e manual. Cada sala octogonal tem oito portas visíveis: N, NE, L, SE, S, SO, O e NO. Uma conexão aponta para a coordenada adjacente e chega pela direção oposta. Passagens normalmente bidirecionais; exceções exigem justificativa de design e suporte explícito.
- Direções sem conexão permanecem seladas. Outras portas poderão depender de progresso. Aproximadamente cinco conexões por sala é uma intenção de densidade, não uma propriedade do protótipo nem obrigação de toda sala periférica.
- Meta intermediária: 26–31 salas; final: 40–60. Expandir depois de validar uma partida completa pequena. Salas devem reutilizar a base e receber conteúdo/configuração independente.
- Início aleatório entre salas previamente validadas como seguras, mantendo o mapa fixo. Futuro balanceamento precisa considerar as rotas e seus requisitos.
- Portas abertas são automáticas; E será usado para objetos e enigmas. Não haverá inventário tradicional. Estados da partida registram pistas, enigmas e desbloqueios.
- Funções de sala combináveis: segura, enigma, pista, efeito mágico, bloqueio e saída. Não exigem bases visuais diferentes.
- Efeitos temporários previstos: controles invertidos, pouca iluminação e zoom intenso. Normalmente terminam ao sair da sala.
- Mapa geral do jogador sem marcador automático de localização. Diário registra pistas descobertas. A prévia completa do editor é uma ferramenta separada.
- Três vidas; pontuação proposta: obrigatório +100, opcional +50, descoberta importante +25, escape +300. Recompensas uma vez por objetivo.
- Câmera acompanha o jogador dentro dos limites da sala; preservar assets e estilo. HUD minimalista de vidas/pontuação. Áudio discreto de passos, portas, mecanismos e magia.
- Fade entre salas: 0,8 s escurecendo + 0,4 s preto + 0,8 s revelando. Tempo nominal de dois segundos, além de eventual custo de carregamento.

## Questões de design abertas

1. Quantidade de saídas, requisitos de cada uma e enigmas obrigatórios/opcionais.
2. Primeiro enigma: regra, pistas, feedback de erro e condição de desbloqueio.
3. Causas da perda de vida, invulnerabilidade temporária, consequências de zerar vidas e regras de reinício.
4. Se pistas e progresso sobrevivem à derrota ou ao retorno ao menu. Persistência durante a partida é necessária; salvar entre sessões não foi exigido.
5. Critério de dificuldade das rotas para o sorteio de spawn; sem o esboço original, posições marcadas P não podem ser inferidas.
6. Teclas de mapa/diário, duração e combinação de efeitos; interação com pausa, transição e reinício.
7. Plataforma de entrega e disponibilidade semanal. Horas do roadmap não são datas de compromisso.

## Escopo mínimo e adiamentos

Uma primeira partida completa precisa de menu/seleção, exploração coerente, spawn seguro, interação, enigma reutilizável, progresso durante a partida, porta condicionada, saída validada e tela de conclusão. Isso valida o ciclo central, mas ainda não conclui toda a visão final.

Para a primeira versão aderente à visão, acrescentar diário/mapa, vidas/derrota/pontuação, efeitos selecionados, saídas alternativas e conteúdo validado. Habilidades exclusivas, salvamento entre sessões, novos sistemas de inventário e refinamento artístico pausado não bloqueiam a validação do ciclo central. O total de 40–60 salas deve ser um marco de conteúdo, não um pré-requisito para testar os sistemas.
