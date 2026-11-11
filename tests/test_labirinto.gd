extends SceneTree
const Map = preload("res://scripts/world/mapa.gd")
const Game = preload("res://scenes/world/labyrinth/labirinto.tscn")
## Relatório desta expansão fica no cache local, sem sobrescrever auditorias antigas.
const OUT := "res://.godot/"
var game: Node2D
var failures: Array[String] = []
var report := {"transitions":[],"sealed":[],"movement":[],"spawns":[],"camera":[],"perimeter":0,"invalid_maps":0}

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		printerr(message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func keys_for(direction: Vector2) -> Array:
	# O navegador de teste pede direção no mundo, compensando o efeito da sala.
	if is_instance_valid(game) and game.player.inverted_controls: direction = -direction
	var keys := []
	if direction.x < -0.1: keys.append(KEY_A)
	if direction.x > 0.1: keys.append(KEY_D)
	if direction.y < -0.1: keys.append(KEY_W)
	if direction.y > 0.1: keys.append(KEY_S)
	return keys

func input_keys(keys: Array, pressed: bool) -> void:
	for key: int in keys:
		var event := InputEventKey.new()
		event.keycode = key as Key
		event.pressed = pressed
		Input.parse_input_event(event)

func free_at(point: Vector2) -> bool:
	var collision: CollisionShape2D = game.player.get_node("CollisionShape2D")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = Transform2D(0,point + collision.position)
	query.collision_mask = 1
	query.exclude = [game.player.get_rid()]
	return game.player.get_world_2d().direct_space_state.intersect_shape(query).is_empty()

func traverse(direction: String, expected: String, character: String) -> void:
	var from: String = game.current_room
	var door: Area2D = game.room.doors[direction]
	var normal := Vector2(Map.DIRECTIONS[direction]).normalized()
	game.player.global_position = door.global_position-normal*144
	game.entry_lock = null
	await frames(3)
	check(game.current_room==from,"Transition triggered before walking " + from + direction)
	var keys := keys_for(normal)
	input_keys(keys,true)
	var ticks := 0
	var fade_started := -1
	var saw_black := false
	while (game.current_room == from or game.transitioning) and ticks < 240:
		await physics_frame
		ticks += 1
		if game.transitioning:
			if fade_started < 0: fade_started = Time.get_ticks_msec()
			check(not game.player.controls_enabled,"Movement enabled during fade")
			check(game.player.velocity.is_zero_approx(),"Moving during fade")
			if game.current_room != from and not saw_black:
				check(game.fade.panel.color.a > 0.99,"Room changed before black")
				saw_black = true
	if fade_started >= 0:
		var elapsed := (Time.get_ticks_msec()-fade_started)/1000.0
		if not report.has("fade_seconds"): report["fade_seconds"] = []
		report.fade_seconds.append(elapsed)
		check(elapsed >= 1.9 and elapsed < 2.4,"Fade duration incorrect: " + str(elapsed))
	check(saw_black,"Black midpoint not observed")
	input_keys(keys,false)
	await frames(3)
	check(game.current_room==expected,"Transition failed %s %s -> %s (%s) at %s" % [from,direction,expected,character,game.player.global_position])
	if game.current_room != expected: return
	var entry: String = Map.OPPOSITE[direction]
	check(game.player.global_position.distance_to(game.room.doors[entry].spawn_position())<16,"Arrival not at opposite portal")
	check(free_at(game.player.global_position),"Blocked arrival: " + expected + entry)
	check(game.entry_lock==game.room.doors[entry],"Arrival lock missing")
	var count: int = game.transition_count
	# Try to force an immediate return while the entry lock is active.
	game.request_transition(game.room.doors[entry],game.player)
	await frames(2)
	check(game.transition_count==count,"Bounced immediately after arrival")
	# Move into the room with real controls; the lock must release itself.
	# A chegada pode ativar ou remover a inversão: recalcula as teclas.
	keys = keys_for(normal)
	input_keys(keys,true)
	# Mede passos de física, não tempo de parede sob carga do editor.
	for attempt in 90:
		await physics_frame
		if game.entry_lock == null: break
	input_keys(keys,false)
	await frames(3)
	check(game.entry_lock==null,"Arrival lock did not release after moving inside %s/%s at %s" % [expected, entry, game.player.global_position])
	report.transitions.append({"character":character,"from":from,"direction":direction,"to":expected,"entry":entry,"ticks":ticks,"free":free_at(game.player.global_position)})

## Envia a mesma ação E usada no jogo para testar o painel e a saída.
func interact() -> void:
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	root.push_input(event)
	await frames(2)
	event = InputEventAction.new()
	event.action = &"interact"
	root.push_input(event)

## Expansão: mede acessibilidade pelas conexões abertas, sem resolver desafios.
func distances(start: String, rooms: Dictionary) -> Dictionary:
	var result := {start: 0}
	var pending: Array[String] = [start]
	while not pending.is_empty():
		var id: String = pending.pop_front()
		for direction: String in rooms[id].links:
			if rooms[id].get("blocked", {}).has(direction): continue
			var target: String = rooms[id].links[direction]
			if result.has(target): continue
			result[target] = result[id] + 1
			pending.append(target)
	return result

## Verifica tamanho, simetria, distâncias aprovadas e estados persistidos nas cenas.
func check_expansion() -> void:
	var rooms := Map.create_rooms()
	check(rooms.size() == 30, "Expected 30 rooms")
	var links := 0
	var blocked := 0
	for id: String in rooms:
		links += rooms[id].links.size()
		blocked += rooms[id].get("blocked", {}).size()
		var preview: Node2D = game.RoomScenes.SCENES[id].instantiate()
		for direction: String in Map.NAMES:
			var door := preview.get_node("Passagens/Porta_" + Map.NAMES[direction])
			var open: bool = rooms[id].links.has(direction) and not rooms[id].get("blocked", {}).has(direction)
			check(door.get_node("GradeFechada").visible == not open, "Editor preview mismatch: " + id + direction)
			check(door.get_node("PlanoDaPorta/BloqueioFechado/Forma").disabled == open, "Editor collision mismatch: " + id + direction)
			check(not door.get_node("Runas").visible, "Runes visible in preview: " + id + direction)
		check(preview.has_node("Saida") == Map.EXITS.has(id), "Exit in wrong scene: " + id)
		preview.free()
	check(links == 106 and blocked == 16, "Expected 45 open and 8 closed connections")
	for start: String in ["S01", "S22", "S23", "S29"]:
		check(distances(start, rooms).size() == 30, "Unreachable room from " + start)
	for start: String in ["S22", "S23", "S29"]:
		var distance := distances(start, rooms)
		var expected: Array = {"S22":[8,6], "S23":[8,6], "S29":[6,7]}[start]
		check(distance.S14 == expected[0] and distance.S21 == expected[1], "Exit route changed: " + start)
	var overview: Node2D = load("res://scenes/world/labyrinth/mapa_editor.tscn").instantiate()
	check(overview.get_node("Salas").get_child_count() == 30, "Overview rooms not persisted")
	check(overview.get_node("Guias").get_child_count() == 53, "Overview connections not persisted")
	check(overview.get_node("Rotulos").get_child_count() == 30, "Overview labels not persisted")
	overview.free()

func run() -> void:
	check(Map.validate(Map.create_rooms()).is_empty(),"Initial spatial map invalid")
	## Expansão: rejeita também uma grade que bloqueia apenas uma face.
	for mutation in ["missing","return","direction","duplicate","overlap","blocked"]:
		var bad := Map.create_rooms()
		match mutation:
			"missing": bad.S01.links.N = "absent"
			"return": bad.S02.links.clear()
			"direction": bad.S01.links.SE = "S02"
			"duplicate": bad.S02.coord = Vector2i.ZERO
			"overlap": bad.S03.coord = Vector2i.ZERO
			"blocked": bad.S01.blocked.clear()
		check(not Map.validate(bad).is_empty(),"Validator accepted " + mutation)
		report.invalid_maps += 1
	game = Game.instantiate()
	# Cenário fixo para testar navegação e E0; nascimentos têm teste próprio.
	game.random_spawn = false
	root.add_child(game)
	await frames(4)
	check(game.current_room=="S01","Default fixed spawn changed")
	# Expansão: valida o esboço e percorre portas abertas em ambos os sentidos.
	check_expansion()
	check(not game.hint_scroll.visible, "Old navigation hint still visible")
	var original_id: int = game.player.get_instance_id()
	for direction: String in ["N","NE","S","SO","O","NO"]:
		var target: String = game.rooms.S01.links[direction]
		await traverse(direction, target, "Aelin")
		if game.current_room == target: await traverse(Map.OPPOSITE[direction], "S01", "Aelin")
		check(game.player.get_instance_id() == original_id, "Player recreated during transition")
		if game.current_room != "S01": game.load_room("S01")
	# Cobre também a diagonal sudeste nova e seu retorno noroeste.
	game.load_room("S05")
	await frames(3)
	await traverse("SE", "S28", "Aelin")
	await traverse("NO", "S05", "Aelin")
	# Inspect every configured room, not just the initial one.
	game.player.set_physics_process(false)
	game.transitioning = true
	for id: String in game.rooms:
		game.load_room(id)
		await frames(3)
		check(free_at(game.player.global_position),"Center spawn blocked " + id)
		report.spawns.append({"room":id,"point":str(game.player.global_position),"free":free_at(game.player.global_position)})
		check(game.find_children("*","Camera2D",true,false).size()==1,"Multiple cameras")
		# Cenas herdadas usam nomes S01...S06; verificar o script comum, não o nome antigo.
		var loaded_rooms := game.find_children("*", "Node2D", true, false).filter(
			func(node: Node): return node.get_script() == preload("res://scripts/world/sala.gd"))
		check(loaded_rooms.size() == 1 and loaded_rooms[0] == game.room, "Adjacent room loaded")
		check(game.room.doors.size()==8,"Door missing " + id)
		for direction: String in game.room.doors:
			var door: Area2D = game.room.doors[direction]
			# Expansão: destino existente não abre uma conexão marcada como bloqueada.
			var expected_open: bool = not door.destination.is_empty() and door.blocked_id.is_empty()
			check(door.opened == expected_open, "Door state mismatch " + id + direction)
			check(not door.get_node("Runas").is_visible_in_tree(), "Runes visible at runtime")
			check(door.get_node("PlanoDaPorta/BloqueioFechado/Forma").disabled==door.opened,"Gate collision mismatch")
			check(free_at(door.spawn_position()),"Door spawn blocked " + id + direction)
			if not door.opened:
				var normal := Vector2(Map.DIRECTIONS[direction]).normalized()
				game.player.global_position = door.global_position-normal*80
				var start: Vector2 = game.player.global_position
				var hit: KinematicCollision2D = game.player.move_and_collide(normal*160)
				check(hit!=null,"Sealed door passed " + id + direction)
				report.sealed.append({"room":id,"direction":direction,"blocked":hit!=null,"distance":game.player.global_position.distance_to(start)})
		# Every edge, including changed user collision corners and open door safety caps.
		for edge in Map.CONTOUR.size():
			var a: Vector2 = Map.CONTOUR[edge]
			var b: Vector2 = Map.CONTOUR[(edge+1)%Map.CONTOUR.size()]
			var outward := (b-a).orthogonal().normalized()
			for sample in 25:
				game.player.global_position = game.room.position+a.lerp(b,sample/24.0)-outward*60
				check(game.player.move_and_collide(outward*160)!=null,"Escaped perimeter %s/%s/%s" % [id,edge,sample])
				report.perimeter += 1
		for p: Vector2 in [Map.CENTER_SPAWN,Vector2(560,256),Vector2(560,896),Vector2(128,576),Vector2(992,576),Vector2(870,370)]:
			game.player.position = p
			game.camera.force_update_scroll()
			await process_frame
			var center: Vector2 = game.camera.get_screen_center_position()
			var half_view: Vector2 = game.camera.get_viewport_rect().size/game.camera.zoom*0.5
			var bounds := Rect2(game.room.position+Map.CAMERA_BOUNDS.position,Map.CAMERA_BOUNDS.size)
			check(bounds.grow(0.2).encloses(Rect2(center-half_view,half_view*2)),"Camera leaked " + id)
			report.camera.append({"room":id,"center":str(center)})
	game.load_room("S01")
	game.transitioning = false
	game.player.set_physics_process(true)
	for direction: Vector2i in Map.DIRECTIONS.values():
		game.player.position = Map.CENTER_SPAWN
		var keys := keys_for(direction)
		input_keys(keys,true)
		await frames(12)
		var speed: float = game.player.velocity.length()
		check(absf(speed-game.player.speed)<0.1,"WASD speed mismatch " + str(direction))
		input_keys(keys,false)
		await frames(3)
		check(game.player.velocity.is_zero_approx(),"Player did not stop")
		report.movement.append({"direction":str(direction),"speed":speed})
	check(game.get_node("Atmosfera/Vinheta").size==Vector2(640,360),"Vignette not covering viewport")
	check(game.camera.zoom==Vector2.ONE,"Zoom changed")
	# Expansão: ambas as saídas encerram a partida; S04 perdeu sua saída antiga.
	for id: String in ["S14", "S21"]:
		game.load_room(id)
		await frames(3)
		game.player.global_position = game.room.get_node("Saida/Interacao").global_position
		await interact()
		check(game.escaped and game.seal_panel.visible, "Exit did not reach victory: " + id)
		game.free()
		game = Game.instantiate()
		# Mantém a nova partida dentro do laço de verificação das saídas.
		game.random_spawn = false
		root.add_child(game)
		await frames(4)
	# Dorian percorre também uma ligação nova, mantendo a escolha do personagem.
	game.free()
	game = Game.instantiate()
	# Cenário fixo para testar navegação e E0; nascimentos têm teste próprio.
	game.random_spawn = false
	game.character_scene = load("res://scenes/characters/players/dorian.tscn")
	root.add_child(game)
	await frames(4)
	await traverse("O", "S10", "Dorian")
	await traverse("L", "S01", "Dorian")
	report["failures"] = failures
	FileAccess.open(OUT+"testes_expansao.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LABIRINTO_RESULT transitions=%s sealed=%s perimeter=%s failures=%s" % [report.transitions.size(),report.sealed.size(),report.perimeter,failures])
	quit(0 if failures.is_empty() else 1)
