extends SceneTree

## Verifica os três pontos reais, as duas personagens e a distribuição do sorteio.
const Game = preload("res://scenes/world/labyrinth/labirinto.tscn")
const Map = preload("res://scripts/world/mapa.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		printerr(message)

func frames(count: int = 4) -> void:
	for i in count: await physics_frame

func run() -> void:
	var chooser: Node2D = Game.instantiate()
	check(chooser.random_spawn, "Sorteio não está habilitado por padrão")
	var counts := {"S22":0, "S23":0, "S29":0}
	var seeds := {}
	for seed_value in range(1, 3001):
		chooser.spawn_seed = seed_value
		var selected: String = chooser.choose_start_room()
		check(counts.has(selected), "Sorteio incluiu sala não autorizada")
		counts[selected] += 1
		seeds[selected] = seed_value
		check(chooser.choose_start_room() == selected, "Semente não reproduz o sorteio")
	for id: String in counts:
		check(counts[id] > 800 and counts[id] < 1200, "Distribuição desequilibrada: " + id)
	chooser.random_spawn = false
	check(chooser.choose_start_room() == "S01", "Modo de teste fixo deixou de funcionar")
	chooser.free()
	for character: String in ["aelin", "dorian"]:
		for id: String in Map.START_ROOMS:
			var game: Node2D = Game.instantiate()
			game.character_scene = load("res://scenes/characters/players/" + character + ".tscn")
			game.spawn_seed = seeds[id]
			root.add_child(game)
			await frames()
			check(game.current_room == id, "Partida não nasceu na sala sorteada")
			check(game.rooms[id].safe, "Início não está marcado seguro")
			check(game.player.global_position == game.room.get_node("Nascimento").global_position, "Ignorou marcador editável")
			check(game.solved_challenges.is_empty(), "Partida herdou desafios resolvidos")
			# Consulta a forma física do personagem em toda a pequena área inicial.
			var shape: CollisionShape2D = game.player.get_node("CollisionShape2D")
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = shape.shape
			query.collision_mask = 1
			query.exclude = [game.player.get_rid()]
			for offset: Vector2 in [Vector2.ZERO, Vector2(32,0), Vector2(-32,0), Vector2(0,32), Vector2(0,-32)]:
				query.transform = Transform2D(0, game.player.global_position + shape.position + offset)
				check(game.player.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "Nascimento obstruído: " + id + character)
			for door: Area2D in game.room.doors.values():
				check(not door.overlaps_body(game.player), "Nasceu em gatilho de transição")
			await frames(8)
			check(game.current_room == id and game.player.controls_enabled, "Nascimento disparou transição ou travou controles")
			# Retornar pela porta não utiliza o ponto de nascimento no centro.
			var entry: String = game.rooms[id].links.keys()[0]
			game.load_room(id, entry)
			check(game.player.global_position == game.room.doors[entry].spawn_position(), "Travessia usou nascimento incorretamente")
			game.free()
	# Finaliza a remoção diferida das salas antes de encerrar o teste.
	await frames()
	print("NASCIMENTOS_RESULT distribuicao=%s falhas=%s" % [counts, failures])
	quit(0 if failures.is_empty() else 1)
