extends Node

const Game = preload("res://scenes/world/labyrinth/labirinto.tscn")
const Map = preload("res://scripts/world/mapa.gd")
var failures: Array[String] = []

# Confere as salas de dica do mapa no HUD do jogo.
func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = Game.instantiate()
	add_child(game)
	# Compara os versos originais com o pergaminho real nas 30 salas.
	var versos := {
		"S11": "Se a treva engolir o chão,\nsegue a luz junto à tua mão.",
		"S17": "Se a treva engolir o chão,\nsegue a luz junto à tua mão.",
		"S13": "Se a pedra parece crescer,\nvai devagar para o rumo entender.",
		"S19": "Se a pedra parece crescer,\nvai devagar para o rumo entender.",
		"S04": "Ao norte, dois arcos te chamam agora:\num busca o poente, o outro a aurora.",
		"S09": "Ao poente, avance sem receio;\na sudoeste, as pedras mostram o veio.",
		"S12": "Ao norte, o corredor guarda o chamado;\no arco do poente espera do outro lado.",
		"S18": "O arco do norte chama à sua frente;\no corredor começa a leste, ascendente.",
		"S22": "O arco do norte ecoa distante;\ndesça ao sul e siga adiante.",
		"S23": "A oeste, dois destinos vais sondar;\na leste, a pedra convida a vagar.",
		"S24": "Desce às galerias, procura o poente;\noutro verso te espera mais à frente.",
		"S29": "Suba ao norte, sem perder a guia;\no poente se alcança pelas galerias.",
	}
	for id: String in game.rooms:
		game.load_room(id)
		var esperado: String = versos.get(id, "")
		if game.interaction_label.text != esperado:
			failures.append("Verso incorreto em " + id)
		# Avisos e comandos devem ocupar o pergaminho sem acumular o verso.
		game.notice = "Aviso temporário"
		game.notice_until = Time.get_ticks_msec() + 1000
		await get_tree().physics_frame
		await get_tree().process_frame
		if game.interaction_label.text != game.notice:
			failures.append("Aviso misturado em " + id)
		game.notice_until = 0
		var centro: Vector2 = game.player.global_position
		# Percorre ambas as faces dos selos e as duas saídas nas salas reais.
		for door in game.room.doors.values():
			var comando := ""
			if not door.blocked_id.is_empty():
				comando = "E — Examinar inscrição"
				game.player.global_position = door.spawn_position()
			elif Map.EXITS.get(id, "") == door.direction:
				comando = "E — Escapar"
				game.player.global_position = game.room.get_node("Saida/Interacao").global_position
			else:
				continue
			await get_tree().physics_frame
			await get_tree().process_frame
			if game.interaction_label.text != comando:
				failures.append("Comando incorreto em " + id)
		game.player.global_position = centro
		await get_tree().physics_frame
		await get_tree().process_frame
		if not esperado.is_empty() and game.interaction_label.text != esperado:
			failures.append("Verso não voltou em " + id)
	print("DICAS_NAVEGACAO_RESULT ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
