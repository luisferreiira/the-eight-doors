# Convenção visual do projeto

- Toda interface ou elemento visual novo deve ter uma cena `.tscn` editável e visível no editor 2D da Godot.
- Persistir nós, layout, fontes, texturas, cores e prévias nas cenas ou recursos. Scripts devem controlar comportamento e estado, preservando ajustes feitos no Inspector.
- Instanciar essas cenas no jogo e nas cenas de contexto apropriadas. Evitar montar interfaces inteiras com `Node.new()` durante a execução.
- Incluir comentários acima dos blocos de código adicionados ou modificados para identificar sua finalidade.
