extends Node
## Verifica escuridão, zoom, inversão e remoção do chão falso nas salas reais.
var failures: Array[String] = []
## Inicia a validação automatizada dos efeitos com as cenas reais do labirinto.
func _ready() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func frames(n: int = 3) -> void:
	for i in n: await get_tree().physics_frame
func run() -> void:
	var game = load("res://scenes/world/labyrinth/labirinto.tscn").instantiate()
	game.random_spawn = false
	get_tree().root.add_child(game)
	await frames()
	# Confirma que a luz móvel acompanha dois personagens em salas diferentes.
	for entry in [{"room":"S11", "character":"aelin"}, {"room":"S17", "character":"dorian"}]:
		if entry.character == "dorian":
			game.free()
			game = load("res://scenes/world/labyrinth/labirinto.tscn").instantiate()
			game.random_spawn = false
			game.character_scene = load("res://scenes/characters/players/dorian.tscn")
			get_tree().root.add_child(game)
			await frames()
		game.load_room(entry.room)
		await frames()
		var light_node: Node2D = game.room.get_node("EfeitoEscuridao")
		var light: PointLight2D = light_node.get_node("Luz")
		check(game.room.get_node("Iluminacao/Ambiente").color.r < 0.2, entry.room + " não escureceu o ambiente")
		var light_before := light.global_position
		game.player.global_position += Vector2(16, 0)
		for process_step in 2:
			await get_tree().process_frame
		check(light.global_position.distance_to(light_before) > 1.0, entry.room + " luz não acompanhou o personagem")
		game.load_room("S01")
		await frames()
		check(game.room.get_node_or_null("EfeitoEscuridao") == null, entry.room + " manteve a escuridão após sair")
	# Confirma a aproximação e restauração ao mudar de sala em cada caso.
	for id in ["S13", "S19"]:
		game.load_room(id)
		await frames()
		check(is_equal_approx(game.camera.zoom.x, 2.2), id + " não aplicou super zoom")
		game.load_room("S01")
		await frames()
		check(game.camera.zoom.is_equal_approx(Vector2.ONE), id + " manteve zoom após sair")
	for id in ["S06", "S07"]:
		game.load_room(id)
		check(game.player.inverted_controls, id + " não inverte")
		Input.action_press("move_right")
		await frames()
		check(game.player.velocity.x < 0, "Direita não move para esquerda")
		Input.action_release("move_right")
		game.load_room("S01")
		check(not game.player.inverted_controls, "Inversão vazou para S01")
	for id in ["S22", "S23", "S29"]:
		game.load_room(id)
		check(game.room_effect == null and not game.player.inverted_controls, "Efeito inesperado na sala")
	# Verifica proteção de todas as entradas e queda em terra encontrada no mapa.
	for id in ["S02", "S08"]:
		game.load_room(id, "S")
		await frames()
		for door in game.room.doors.values():
			check(not game.room_effect.is_false_floor(door.spawn_position()), "Entrada insegura")
		var dirt := Vector2.ZERO
		for x in range(300,800,16):
			for y in range(360,800,16):
				var point = game.room.to_global(Vector2(x,y))
				if game.room_effect.is_false_floor(point): dirt = point
		check(dirt != Vector2.ZERO, "Não restou terra falsa")
		game.player.global_position = dirt
		await frames()
		check(game.falling, "Terra não provoca queda")
		await get_tree().create_timer(0.8).timeout
		check(not game.falling and game.player.controls_enabled, "Recuperação falhou")
		check(game.player.global_position.distance_to(game.return_position)<1, "Retorno incorreto")
	game.free()
	await frames()
	print("EFEITOS_RESULT falhas=", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
