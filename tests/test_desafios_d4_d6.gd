extends Node

const Map = preload("res://scripts/world/mapa.gd")
const Game = preload("res://scenes/world/labyrinth/labirinto.tscn")
var game: Node
var failures: Array[String] = []

# Registra falhas sem interromper os demais cenários de validação.
func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr(message)

# Inicializa o labirinto em uma sala determinística para percorrer as duas faces.
func _ready() -> void:
	call_deferred("_run")

# Envia a ação de interação usada pelo jogo para o personagem próximo ao marcador.
func interact() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	game.call("_unhandled_input", event)

# Abre um painel pelo lado indicado, como se o jogador estivesse diante da porta.
func open_challenge(room_id: String, direction: String, challenge_id: String) -> Area2D:
	game.call("load_room", room_id)
	await get_tree().physics_frame
	var door: Area2D = game.get("room").doors[direction]
	check(door.blocked_id == challenge_id, "%s não está na face %s/%s." % [challenge_id, room_id, direction])
	game.get("player").global_position = door.spawn_position()
	interact()
	check(game.get("active_challenge") == door, "%s não abriu pela face %s/%s." % [challenge_id, room_id, direction])
	return door

# Envia escolhas pela mesma interface de botões usada pelo jogo.
func answer(sequence: Array) -> void:
	var panel: CanvasLayer = game.get("seal_panel")
	for choice: String in sequence:
		panel.call("_select_choice", choice)
	panel.call("_confirm")

# Confirma tamanho, centralização e limites do painel editável durante a execução.
func check_panel_layout(challenge_id: String) -> void:
	await get_tree().process_frame
	var frame := (game.get("seal_panel") as CanvasLayer).get_node("Overlay/Centro/Moldura") as Control
	var bounds := frame.get_global_rect()
	var viewport := get_tree().root.get_viewport().get_visible_rect()
	check(bounds.size.x <= 520.0, "%s continua largo demais: %s px." % [challenge_id, bounds.size.x])
	check(bounds.size.y <= 320.0, "%s continua alto demais: %s px." % [challenge_id, bounds.size.y])
	check(bounds.position.x >= 0.0 and bounds.end.x <= viewport.size.x, "%s ficou cortado horizontalmente." % challenge_id)
	check(bounds.position.y >= 0.0 and bounds.end.y <= viewport.size.y, "%s ficou cortado verticalmente." % challenge_id)
	var center_error := bounds.get_center().distance_to(viewport.get_center())
	check(center_error <= 4.0, "%s deixou de ficar centralizado: erro de %s px." % [challenge_id, center_error])
	check(frame.get_node_or_null("Conteudo/Dica") == null, "%s ainda mostra a dica dentro do painel." % challenge_id)
	print("LAYOUT_%s %s" % [challenge_id, bounds.size])

# Confirma que cada pergaminho fica na sala da própria pista, longe das salas das portas.
func test_clue_indicators() -> void:
	var clue_rooms := {
		"D4": ["S29", "Não sou flor, mas abro pétalas para mostrar todos os rumos."],
		"D5": ["S08", "A espiral desperta; o olho observa; três talhos encerram o rito."],
		"D6": ["S15", "Da noite sem luz, a Lua cresce até a face plena; então mingua e desaparece."]
	}
	for challenge_id: String in clue_rooms:
		var clue_room_id: String = clue_rooms[challenge_id][0]
		game.call("load_room", clue_room_id)
		var clue: Marker2D = game.get("room").get_node("ConteudoDaSala/Interacoes/PistaDesafio")
		check(clue.get("texto") == clue_rooms[challenge_id][1], "%s não tem sua pista na sala %s." % [challenge_id, clue_room_id])
		check(clue.position.distance_to(Vector2(560, 640)) <= 100.0, "%s ficou fora do centro da sala da pista." % challenge_id)
		check(clue.get_node_or_null("Pergaminho") is Sprite2D, "%s não tem pergaminho visual junto à pista." % clue_room_id)
		check(clue.get_node_or_null("Interrogacao") is Label, "%s não tem símbolo no pergaminho." % clue_room_id)
		if clue_room_id == "S08":
			var effect: Node2D = game.get("room_effect")
			check(not effect.is_false_floor(clue.global_position), "O pergaminho da S08 ficou sobre o chão falso.")
		game.get("player").global_position = clue.global_position
		interact()
		check(String(game.get("notice")) == clue_rooms[challenge_id][1], "%s não revelou sua pista ao interagir com o pergaminho." % challenge_id)
	for room_id: String in ["S02", "S06", "S07", "S09", "S16", "S30"]:
		game.call("load_room", room_id)
		check(game.get("room").get_node_or_null("ConteudoDaSala/Interacoes/IndicadorPista") == null, "%s ainda tem pergaminho na sala do desafio." % room_id)

# Verifica que as duas saídas continuam alcançáveis sem abrir nenhum selo.
func can_reach(start: String, destination: String) -> bool:
	var rooms: Dictionary = Map.create_rooms()
	var pending: Array[String] = [start]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var current: String = pending.pop_front()
		if current == destination:
			return true
		if visited.has(current):
			continue
		visited[current] = true
		var config: Dictionary = rooms[current]
		for direction: String in config.links:
			if config.get("blocked", {}).has(direction):
				continue
			pending.append(config.links[direction])
	return false

# Exercita tentativas partilhadas, penalidade e pontuação única em cada desafio.
func _run() -> void:
	game = Game.instantiate()
	game.set("random_spawn", false)
	get_tree().root.add_child(game)
	await get_tree().physics_frame
	await test_clue_indicators()

	# D4: três respostas erradas distribuídas pelas duas faces custam uma vida.
	await open_challenge("S06", "S", "D4")
	await check_panel_layout("D4")
	answer(["Viajante"])
	check(game.get("challenge_errors").get("D4", 0) == 1, "D4 não registrou o primeiro erro.")
	game.call("_close_challenge")
	await open_challenge("S30", "N", "D4")
	answer(["Torre"])
	check(game.get("challenge_errors").get("D4", 0) == 2, "D4 não compartilhou erros entre as faces.")
	answer(["Poço"])
	check(game.get("lives") == 2 and not game.get("seal_panel").visible, "D4 não aplicou a perda de vida após três erros.")

	# D4 resolve pela face oposta e abre as duas faces com o bônus ajustado.
	await open_challenge("S30", "N", "D4")
	answer(["Rosa"])
	await get_tree().create_timer(0.8).timeout
	check(game.get("score") == 100 and game.get("solved_challenges").has("D4"), "D4 não pontuou pelo histórico de erros.")
	game.call("load_room", "S06")
	check(game.get("room").doors["S"].opened, "D4 não abriu a face S06/S.")
	check(game.get("score") == 100, "D4 concedeu pontos novamente pela segunda face.")

	# D5 resolve pela primeira face e persiste ao carregar a face oposta.
	await open_challenge("S07", "SO", "D5")
	await check_panel_layout("D5")
	answer(["Espiral", "Olho", "Três talhos"])
	await get_tree().create_timer(0.8).timeout
	check(game.get("score") == 400 and game.get("solved_challenges").has("D5"), "D5 não aplicou a solução ou pontuação.")
	game.call("load_room", "S09")
	check(game.get("room").doors["NE"].opened, "D5 não compartilhou a abertura com S09/NE.")
	check(game.get("score") == 400, "D5 duplicou a pontuação na segunda face.")

	# D6 mantém um erro entre as faces e aceita a sequência lunar completa.
	await open_challenge("S02", "NE", "D6")
	await check_panel_layout("D6")
	answer(["Lua Cheia", "Lua Nova", "Quarto Minguante", "Quarto Crescente"])
	check(game.get("challenge_errors").get("D6", 0) == 1, "D6 não registrou a resposta incorreta.")
	game.call("_close_challenge")
	await open_challenge("S16", "SO", "D6")
	answer(["Lua Nova", "Quarto Crescente", "Lua Cheia", "Quarto Minguante"])
	await get_tree().create_timer(0.8).timeout
	check(game.get("score") == 600 and game.get("solved_challenges").has("D6"), "D6 não aplicou o bônus com um erro.")
	game.call("load_room", "S02")
	check(game.get("room").doors["NE"].opened, "D6 não compartilhou a abertura com S02/NE.")
	check(game.get("score") == 600, "D6 duplicou a pontuação na segunda face.")

	# As duas saídas permanecem alcançáveis por todos os inícios com selos fechados.
	for start: String in Map.START_ROOMS:
		for destination: String in Map.EXITS:
			check(can_reach(start, destination), "A saída %s ficou inacessível partindo de %s." % [destination, start])
	print("DESAFIOS_RESULT ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
