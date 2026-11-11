extends SceneTree
## Verifica inversão, restauração e remoção do chão falso nas salas reais.
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func frames(n: int = 3) -> void:
	for i in n: await physics_frame
func run() -> void:
	var game = load("res://scenes/world/labyrinth/labirinto.tscn").instantiate()
	game.random_spawn = false
	root.add_child(game)
	await frames()
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
		await create_timer(0.8).timeout
		check(not game.falling and game.player.controls_enabled, "Recuperação falhou")
		check(game.player.global_position.distance_to(game.return_position)<1, "Retorno incorreto")
	game.free()
	await frames()
	print("EFEITOS_RESULT falhas=", failures)
	quit(0 if failures.is_empty() else 1)
