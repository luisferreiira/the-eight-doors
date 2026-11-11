# Efeitos ativos

S06/S07 mantêm controles invertidos. S02/S08 usam chão falso baseado nos tiles reais de Piso e TransicoesPiso: pedra sustenta, terra provoca queda e retorno à entrada, sem perda de vida.

Os caminhos de pedra estão gravados em TransicoesPiso nas cenas individuais, com textura original, largura de aproximadamente 48 pixels e rotas calculadas ao redor das colisões até as oito portas. São editáveis com o pincel de tiles no editor 2D. A leitura tem margem de dois pixels nas bordas e proteção ao redor das entradas.

O script efeito_sala.gd reconhece pedra pelo source 3, coordenadas de atlas x=6..43 e y=24..27. Se o atlas for reorganizado, atualizar essa classificação. Não ativar colisões sólidas no chão: o efeito consulta os pés, permitindo caminhar sobre pedra.

Pista: Onde a terra promete, desconfia do chão; na frieza da pedra, encontra sustentação.

labirinto.gd controla queda, restauração visual e retorno. O teste test_efeitos_salas.gd verifica inversão, entradas, queda, recuperação e nascimentos seguros.
