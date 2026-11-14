extends SceneTree
var failures = []
var game
func _initialize(): call_deferred("run")
func check(ok, message):
 if not ok: failures.append(message)
func open_door(room_id, direction):
 game.load_room(room_id,direction)
 var event = InputEventAction.new()
 event.action = "interact"
 event.pressed = true
 game._unhandled_input(event)
func answer(text):
 game.seal_panel.field.text = text
 game.seal_panel._confirm()
func new_game():
 game = load("res://scenes/world/labyrinth/labirinto.tscn").instantiate()
 game.random_spawn = false
 root.add_child(game)
 current_scene = game
func run():
 new_game()
 await physics_frame
 # Erros persistem após fechar, sair e reabrir pela face oposta.
 open_door("S23","S")
 answer("errado")
 game._close_challenge()
 open_door("S26","N")
 check(game.challenge_errors.D3 == 1, "Perdeu histórico")
 answer("errado")
 check(game.seal_panel.get_node("Fundo/Painel/Feedback").text.contains("1 vida"), "Não avisou última chance")
 answer("errado")
 check(game.lives == 2 and not game.seal_panel.visible, "Três erros não custaram vida")
 open_door("S23","S")
 answer("O")
 await create_timer(0.8).timeout
 check(game.score == 100 and game.solved_challenges.has("D3"), "Bônus após perder vida incorreto")
 game.load_room("S26","N")
 check(game.room.doors.N.opened and game.score == 100, "Duplicou bônus ou fechou passagem")
 open_door("S03","NE")
 answer("SO")
 await create_timer(0.8).timeout
 check(game.score == 400, "Acerto sem erros não vale 300")
 open_door("S04","SE")
 answer("errado")
 answer("L")
 await create_timer(0.8).timeout
 check(game.score == 600, "Acerto com um erro não vale 200")
 game._finish_run(true)
 check(game.score == 1300 and game.finished and game.escaped, "Bônus fuga incorreto")
 game._finish_run(true)
 check(game.score == 1300, "Bônus fuga duplicado")
 game.free()
 new_game()
 await physics_frame
 check(game.score == 0 and game.lives == 3 and game.challenge_errors.is_empty(), "Reinício herdou estado")
 # Animação real da queda: primeira grátis e três penalizadas.
 for index in range(4):
  game.falling = true
  game._lock_player()
  await game._recover_from_fall()
  check(game.lives == maxi(0,3-index), "Dano da queda incorreto")
  # Corações e placar representam o estado real sem criar nós em execução.
  var hud = game.get_node("HUD/Status")
  check(hud.coracao_cheio != null and hud.coracao_vazio != null, "Texturas do HUD ausentes")
  for heart in range(3):
   var expected = hud.coracao_cheio if heart < game.lives else hud.coracao_vazio
   check(hud.get_node("Coracao" + str(heart+1)).texture == expected, "Coração incorreto")
  check(hud.get_node("Pontos").text == "Pontos: %s" % game.score, "Placar desatualizado")
 check(game.finished and not game.escaped and not game.player.controls_enabled and game.get_node("Resultado").visible, "Derrota não encerrou")
 game.free()
 new_game()
 await physics_frame
 # Duas falhas ainda na primeira rodada rendem apenas 100 pontos.
 open_door("S25","SO")
 answer("errado")
 answer("errado")
 answer("NO")
 await create_timer(0.8).timeout
 check(game.score == 100 and game.lives == 3, "Dois erros penalizaram vida ou bônus incorretamente")
 # Três rodadas esgotadas encerram também por erros, sem pontuar respostas erradas.
 for round_index in range(3):
  open_door("S23","S")
  for attempt in range(3): answer("errado")
 check(game.finished and game.lives == 0 and game.score == 100, "Derrota por enigma incorreta")
 game.free()
 await physics_frame
 print("PONTUACAO_RESULT ", failures)
 quit(0 if failures.is_empty() else 1)
