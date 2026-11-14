# Pontuação e vidas

Cada partida começa com 3 vidas e zero pontos. O estado fica em labirinto.gd e é descartado ao reiniciar.

## Portas

Cada ID de desafio guarda o total de erros, compartilhado pelos dois lados. A cada três erros perde-se uma vida, fecha-se o painel e uma nova rodada de três tentativas fica disponível. Sair da sala ou fechar o painel não apaga erros. Portas não são seladas permanentemente.

Acertos concedem 300 pontos sem erros, 200 após um erro e 100 após dois ou mais erros. O prêmio ocorre somente após a animação de abertura, uma vez por ID. Novas rodadas de tentativas não restauram o prêmio máximo. Campos vazios e sequências incompletas não contam como erro.

## Quedas e fim

A primeira queda da partida é gratuita, com aviso no HUD. As seguintes custam uma vida. Zero vidas encerra a partida, bloqueia movimento/interações e mostra o resultado. Escapar concede 500 pontos mais 100 por vida restante, uma única vez.

## Edição

O HUD instancia scenes/ui/gameplay/hud_status.tscn: três corações vinho, pontuação e moldura compacta. Sala e personagem ficam abaixo. Avisos temporários aparecem no pergaminho por seis segundos; comandos próximos têm prioridade. scripts/ui/hud_status.gd atualiza apenas texturas e texto, preservando o layout. O nó Resultado instancia scenes/ui/gameplay/vitoria.tscn para vitória e derrota. Os painéis usam seus Labels de Feedback para tentativas e aviso antes da última resposta.

Os textos de estado são atualizados pelo script; layout, fontes, cores e molduras permanecem editáveis nas cenas. As regras estão em _confirm_challenge, _recover_from_fall, _refresh_attempts, _lose_life e _finish_run.

## Testes

 tests/test_pontuacao_vidas.gd cobre bônus, persistência dos erros entre faces, três tentativas, novas rodadas, primeira queda gratuita, derrota por quedas e erros, bônus de fuga sem duplicação e reinício limpo.
