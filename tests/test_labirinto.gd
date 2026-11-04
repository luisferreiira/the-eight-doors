extends SceneTree
const Map = preload("res://scripts/world/mapa.gd")
const Game = preload("res://scenes/world/labyrinth/labirinto.tscn")
const OUT := "res://docs/history/expansao_2026-10-30/"
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
	input_keys(keys,true)
	# Mede passos de física, não tempo de parede sob carga do editor.
	for attempt in 90:
		await physics_frame
		if game.entry_lock == null: break
	input_keys(keys,false)
	await frames(3)
	check(game.entry_lock==null,"Arrival lock did not release after moving inside %s/%s at %s" % [expected, entry, game.player.global_position])
	report.transitions.append({"character":character,"from":from,"direction":direction,"to":expected,"entry":entry,"ticks":ticks,"free":free_at(game.player.global_position)})

func run() -> void:
	check(Map.validate(Map.create_rooms()).is_empty(),"Initial spatial map invalid")
	for mutation in ["missing","return","direction","duplicate","overlap"]:
		var bad := Map.create_rooms()
		match mutation:
			"missing": bad.S01.links.N = "absent"
			"return": bad.S02.links.clear()
			"direction": bad.S01.links.SE = "S02"
			"duplicate": bad.S02.coord = Vector2i.ZERO
			"overlap": bad.S03.coord = Vector2i.ZERO
		check(not Map.validate(bad).is_empty(),"Validator accepted " + mutation)
		report.invalid_maps += 1
	game = Game.instantiate()
	root.add_child(game)
	await frames(4)
	check(game.current_room=="S01","Default fixed spawn changed")
	var original_id: int = game.player.get_instance_id()
	for direction: String in ["N","NE","L","S","SO"]:
		var target: String = game.rooms.S01.links[direction]
		await traverse(direction,target,"Aelin")
		if game.current_room == target: await traverse(Map.OPPOSITE[direction],"S01","Aelin")
		check(game.player.get_instance_id()==original_id,"Player recreated during transition")
		if game.current_room != "S01": game.load_room("S01")
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
			check(door.opened==not door.destination.is_empty(),"Door state mismatch " + id + direction)
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
	# Dorian uses the same exported scene slot without any edits to his scene.
	game.free()
	game = Game.instantiate()
	game.character_scene = load("res://scenes/characters/players/dorian.tscn")
	game.random_spawn = true
	game.spawn_seed = 42
	root.add_child(game)
	await frames(4)
	check(game.rooms[game.current_room].safe and free_at(game.player.global_position),"Random safe spawn failed")
	report["random_spawn"] = game.current_room
	game.load_room("S01")
	await frames(3)
	for direction: String in ["N","NE","L","S","SO"]:
		var target: String = game.rooms.S01.links[direction]
		await traverse(direction,target,"Dorian")
		if game.current_room==target: await traverse(Map.OPPOSITE[direction],"S01","Dorian")
		if game.current_room!="S01": game.load_room("S01")
	report["failures"] = failures
	FileAccess.open(OUT+"testes.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LABIRINTO_RESULT transitions=%s sealed=%s perimeter=%s failures=%s" % [report.transitions.size(),report.sealed.size(),report.perimeter,failures])
	quit(0 if failures.is_empty() else 1)
