extends Node

const Map = preload("res://scripts/world/mapa.gd")
const Game = preload("res://scenes/world/labyrinth/labirinto.tscn")
var game: Node
var failures: Array[String] = []

# Registra cada falha para verificar todos os inícios e inscrições em uma execução.
func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr(message)

# Aciona a mesma tecla E que o jogador usa para ler as inscrições.
func interact() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	game.call("_unhandled_input", event)

# Valida as dicas automáticas nos três nascimentos seguros.
func test_starting_hints() -> void:
	var expected := {
		"S22": "O arco do norte ecoa distante;\ndesça ao sul e siga adiante.",
		"S23": "Pelo centro, a oeste abre-se o caminho;\nao norte, o alto guarda o destino.",
		"S29": "Suba ao norte, sem perder a guia;\no poente se alcança pelas galerias."
	}
	for room_id: String in expected:
		game.call("load_room", room_id)
		await get_tree().process_frame
		game.call("_update_interaction_hint")
		check(game.get("notice") == expected[room_id], "%s não recebeu sua dica automática." % room_id)
		check(game.get("interaction_label").text == expected[room_id], "%s não mostrou o verso no pergaminho." % room_id)
		check(game.get("hint_scroll").visible, "O pergaminho automático de %s está oculto." % room_id)

# Valida os versos locais e a interação independente das pistas de enigmas.
func test_optional_inscriptions() -> void:
	var expected := {
		"S09": "Ao poente, avance sem receio;\na sudoeste, as pedras mostram o veio.",
		"S12": "Ao norte, o corredor guarda o chamado;\no arco do poente espera do outro lado.",
		"S04": "Ao norte, uma passagem segue a leste;\npor ela, o rumo se tece.",
		"S18": "O arco do norte chama à sua frente;\no corredor começa a leste, ascendente.",
		"S24": "Galerias altas aguardam seu passo;\nbusque o centro, siga o compasso."
	}
	for room_id: String in expected:
		game.call("load_room", room_id)
		await get_tree().physics_frame
		var inscription: Marker2D = game.get("room").get_node("ConteudoDaSala/Interacoes/InscricaoNavegacao")
		check(inscription.get("texto") == expected[room_id], "%s contém um verso incorreto." % room_id)
		check(inscription.get_node_or_null("Pergaminho") is Sprite2D, "%s não tem o pergaminho visual." % room_id)
		game.get("player").global_position = inscription.global_position
		game.call("_update_interaction_hint")
		check(game.get("interaction_label").text == "E — Ler inscrição", "%s não mostra o comando de E." % room_id)
		check(game.call("_near_clue") == null, "%s confundiu a inscrição de navegação com a pista de um enigma." % room_id)
		interact()
		check(game.get("notice") == expected[room_id], "%s não exibiu o verso ao pressionar E." % room_id)

# Confirma os primeiros passos citados pelos versos nas conexões reais do mapa.
func test_hint_directions() -> void:
	var rooms: Dictionary = Map.create_rooms()
	check(rooms["S22"].links["S"] == "S16", "A dica de S22 não começa pela ligação sul real.")
	check(rooms["S23"].links["O"] == "S04" and rooms["S04"].links["N"] == "S03" and rooms["S03"].links["L"] == "S18", "A dica central de S23 não corresponde às ligações reais.")
	check(rooms["S29"].links["N"] == "S05" and rooms["S05"].links["O"] == "S06", "A dica de S29 não aponta para as galerias ocidentais.")
	check(rooms["S09"].links["SO"] == "S12", "A dica de S09 não corresponde à ligação sudoeste.")
	check(rooms["S12"].links["N"] == "S13" and rooms["S13"].links["N"] == "S14", "A dica de S12 não conduz ao arco oeste.")
	check(rooms["S04"].links["N"] == "S03" and rooms["S03"].links["L"] == "S18", "A dica de S04 não corresponde ao norte e à passagem leste.")
	check(rooms["S18"].links["L"] == "S19", "A dica de S18 não corresponde ao corredor leste.")
	check(rooms["S24"].links["O"] == "S23", "A dica de S24 não aponta para a região central.")
	check(Map.EXITS["S14"] == "O" and Map.EXITS["S21"] == "N", "As saídas do mapa mudaram inesperadamente.")

# Executa as verificações com o mesmo labirinto usado no jogo.
func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	game = Game.instantiate()
	game.set("random_spawn", false)
	get_tree().root.add_child(game)
	await get_tree().physics_frame
	test_hint_directions()
	await test_starting_hints()
	await test_optional_inscriptions()
	print("DICAS_NAVEGACAO_RESULT ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
