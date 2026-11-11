# Pausa em pedra e transição de reinício

## Interface editável

`scenes/ui/gameplay/pausa.tscn` contém toda a interface: moldura de pedra, título em tom de inscrição, botões, legendas, controle de volume e tema dos tooltips. O controlador `scripts/autoload/pause_overlay.gd` instancia a cena e conecta as ações, preservando o layout do Inspector.

O texto ao passar sobre o botão de reiniciar foi reduzido para **Reiniciar**, com fonte de 10 pixels e uma caixa compacta. As legendas **Continuar** e **Reiniciar** também ficam visíveis abaixo dos ícones.

## Fade de reinício

`scenes/ui/gameplay/fade_reinicio.tscn` permanece no autoload durante a troca da partida, acima das outras interfaces. O `AnimationPlayer` contém:

- **escurecer:** 0,45 s até a tela ficar totalmente preta;
- carregamento da nova cena sob preto completo;
- **revelar:** mantém preto por 0,2 s e revela em 0,5 s.

O mundo permanece pausado durante a transição. Cliques e comandos repetidos são bloqueados. Ao terminar, a nova partida recupera os controles, preserva o personagem escolhido e usa o sorteio de nascimento existente. A volta ao menu também usa essa transição.

## Verificação

`tests/test_pausa.gd` verifica a cena editável, o tamanho do tooltip, o escurecimento antes da recarga, a opacidade completa no momento da troca, o bloqueio de cliques duplicados, a preservação do personagem e a retomada dos controles. Use `-- --capture` com renderização para registrar pausa, hover e reinício. A integração de menus aguarda o término real do fade.
