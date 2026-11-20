extends Node

const Game = preload("res://scenes/world/labyrinth/labirinto.tscn")
var failures: Array[String] = []

# Registra falhas sem interromper a validação da outra saída.
func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr(message)

# Pressiona E, confirma a abertura e atravessa a saída usando os controles reais.
func test_exit(room_id: String, action: String) -> void:
	var game: Node = Game.instantiate()
	game.set("random_spawn", false)
	get_tree().root.add_child(game)
	await get_tree().physics_frame
	game.call("load_room", room_id)
	await get_tree().physics_frame
	var marker: Marker2D = game.get("room").get_node("Saida/Interacao")
	game.get("player").global_position = marker.global_position
	game.set("score", 1000)
	game.set("lives", 2)
	var sequence: CanvasLayer = game.get_node("SequenciaVitoria")
	sequence.set("dissolve_duration", 0.5)
	sequence.set("white_hold_duration", 0.03)
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	game.call("_unhandled_input", event)
	check(game.get("victory_traversal_active"), "%s não iniciou abertura da saída ao pressionar E." % room_id)
	check(not game.get("finished") and not sequence.visible, "%s iniciou a finalização antes de abrir e atravessar." % room_id)
	check(not game.get("player").controls_enabled, "%s permitiu movimento durante a abertura." % room_id)
	check(game.get("score") == 1000, "%s pontuou antes da travessia." % room_id)
	var door: Area2D = game.get("victory_exit_door")
	var open_wait := 0
	while not door.opened and open_wait < 90:
		await get_tree().physics_frame
		open_wait += 1
	check(door.opened and not door.opening, "%s não terminou de abrir a porta." % room_id)
	check(game.get("player").controls_enabled, "%s não liberou o movimento após abrir." % room_id)
	check(not sequence.visible and not game.get("finished"), "%s iniciou o branco antes de atravessar." % room_id)
	var passage: Marker2D = game.get("room").get_node("Saida/Passagem")
	var initial_position: Vector2 = game.get("player").global_position
	Input.action_press(action)
	var move_wait := 0
	while not game.get("victory_crossed") and move_wait < 180:
		await get_tree().physics_frame
		move_wait += 1
	Input.action_release(action)
	await get_tree().physics_frame
	var blockers: Array[String] = []
	for collision_index in game.get("player").get_slide_collision_count():
		blockers.append(str(game.get("player").get_slide_collision(collision_index).get_collider().get_path()))
	check(game.get("victory_crossed"), "%s personagem não atravessou o vão (posição %s; alvo %s; colisores %s)." % [room_id, game.get("player").global_position, passage.global_position, blockers])
	check(game.get("player").global_position != initial_position, "%s personagem não caminhou pela passagem." % room_id)
	check(game.get("finished") and game.get("escaped"), "%s não concluiu a partida após cruzar." % room_id)
	check(not game.get("player").controls_enabled, "%s manteve controles durante a dissolução." % room_id)
	check(game.get("score") == 1700, "%s não preservou o bônus final exatamente uma vez." % room_id)
	check(sequence.visible, "%s não iniciou dissolução após atravessar." % room_id)
	event = InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	game.call("_unhandled_input", event)
	game.call("_finish_run", true)
	check(game.get("score") == 1700, "%s contou o bônus mais de uma vez." % room_id)
	await sequence.completed
	await get_tree().process_frame
	check(sequence.visible, "%s não manteve o branco final visível." % room_id)
	check(game.get_node("Resultado").visible, "%s não mostrou o resultado final." % room_id)
	check(game.get_node("Resultado/Overlay/Centro/Moldura/Conteudo/Titulo").text == "Você escapou!", "%s não mostrou a mensagem de vitória." % room_id)
	check(game.get_node("Resultado/Overlay/Centro/Moldura/Conteudo/Inscricao").text.contains("1700"), "%s perdeu a pontuação final." % room_id)
	var dissolve: ShaderMaterial = sequence.get_node("VeloBranco").material
	check(is_equal_approx(dissolve.get_shader_parameter("progress"), 1.0), "%s não concluiu o desmanche em branco." % room_id)
	check(game.get_node("Resultado/Overlay/Centro/Moldura/Conteudo/Acoes/Reiniciar").pressed.get_connections().size() > 0, "Botão de reinício desconectado.")
	check(game.get_node("Resultado/Overlay/Centro/Moldura/Conteudo/Acoes/Menu").pressed.get_connections().size() > 0, "Botão de menu desconectado.")
	game.free()
	await get_tree().physics_frame

# Executa a sequência completa pelas duas saídas externas.
func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await test_exit("S14", "move_left")
	await test_exit("S21", "move_up")
	print("SEQUENCIA_VITORIA_RESULT ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
