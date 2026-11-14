extends SceneTree
var failures = []
func _initialize(): call_deferred("run")
func run():
 var game = load("res://scenes/world/labyrinth/labirinto.tscn").instantiate()
 game.random_spawn = false
 root.add_child(game)
 current_scene = game
 await physics_frame
 for item in [["D3","S23","S","O"],["D7","S03","NE","SO"],["D8","S04","SE","E"],["D9","S25","SO","NO"]]:
  game.load_room(item[1],item[2])
  game.player.global_position = game.room.doors[item[2]].spawn_position()
  var event = InputEventAction.new()
  event.action = "interact"
  event.pressed = true
  game._unhandled_input(event)
  var panel = game.seal_panel
  if panel != game.get_node(item[0]): failures.append("painel " + item[0]); continue
  # Pausar mantém inscrição, texto e bloqueio do movimento; continuar restaura foco.
  panel.field.text = "rascunho"
  var pause = root.get_node("PauseOverlay")
  pause._pause_game()
  if not paused or not panel.visible: failures.append("não pausou sobre enigma")
  pause._resume_game()
  if paused or panel.field.text != "rascunho" or game.player.controls_enabled: failures.append("retomada perdeu estado")
  # A arte cobre o tile original; o ator se eleva quando cruza a porta.
  var visual = game.room.doors[item[2]].get_node_or_null("VisualEspecial")
  if visual != null:
   game.player._update_door_depth()
   if visual.get_node("Moldura").z_index != 4 or visual.get_node("Grade").z_index != 5: failures.append("arte atrás dos tiles")
   if not visual.get_node("Grade").visible: failures.append("grade fechada invisível")
   # As portas inferiores ficam à frente; a porta nordeste fica atrás do ator.
   if item[2] in ["S", "SE", "SO"]:
    if game.player.z_index != game.player.normal_z: failures.append("ator sobre porta inferior")
   elif game.player.z_index <= 5: failures.append("ator atrás da porta superior")
  panel.field.text = "errado"
  panel._confirm()
  if game.solved_challenges.has(item[0]): failures.append("aceitou erro")
  if not panel.field.text.is_empty(): failures.append("resposta não foi limpa")
  panel.field.text = item[3]
  panel._confirm()
  await create_timer(0.9).timeout
  if not game.solved_challenges.has(item[0]): failures.append("não abriu " + item[0])
  var target = game.rooms[item[1]].links[item[2]]
  var opposite = game.Map.OPPOSITE[item[2]]
  game.load_room(target,opposite)
  if not game.room.doors[opposite].opened: failures.append("face oposta fechada")
 game.free()
 await physics_frame
 print("DIRECOES_RESULT ", failures)
 quit(0 if failures.is_empty() else 1)
