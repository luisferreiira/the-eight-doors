extends SceneTree
const DOC := "res://docs/history/cena_principal_2026-10-27/"
var failures: Array[String] = []
var report: Dictionary = {"perimeter":[], "pillars":[], "movement":[], "camera":[]}
var room: Node2D
var player: CharacterBody2D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func run() -> void:
	room = load("res://scenes/world/environments/sala_central_jogavel.tscn").instantiate()
	root.add_child(room)
	player = room.get_node("Aelin")
	player.set_physics_process(false)
	for i in 3: await physics_frame
	# Sweep the actual player's foot capsule through every edge, including door gaps.
	var contour := PackedVector2Array([Vector2(320,192),Vector2(800,192),Vector2(1056,448),Vector2(1056,704),Vector2(800,960),Vector2(320,960),Vector2(64,704),Vector2(64,448)])
	for edge in contour.size():
		var a := contour[edge]
		var b := contour[(edge+1) % contour.size()]
		var outward := (b-a).orthogonal().normalized()
		var samples := ceili(a.distance_to(b)/16.0)
		for sample in range(samples+1):
			var boundary := a.lerp(b, float(sample)/samples)
			var start := boundary - outward * 56.0
			player.position = start
			var hit := player.move_and_collide(outward * 144.0)
			var blocked := hit != null and (player.position-start).dot(outward) < 80.0
			check(blocked, "Perimeter escape edge=%s sample=%s position=%s" % [edge,sample,player.position])
			report.perimeter.append({"edge":edge,"sample":sample,"blocked":blocked})
	for column in room.get_node("Elementos/Colunas").get_children():
		for direction: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			player.position = column.position - direction*64.0
			var hit := player.move_and_collide(direction*128.0)
			check(hit != null, "Pillar not solid " + str(column.name))
			report.pillars.append({"name":str(column.name),"direction":str(direction),"blocked":hit!=null})
	# Real input events exercise the existing controller; no character script changes.
	for keys in [[KEY_W],[KEY_S],[KEY_A],[KEY_D],[KEY_W,KEY_A],[KEY_W,KEY_D],[KEY_S,KEY_A],[KEY_S,KEY_D]]:
		player.position = Vector2(560,672)
		player.velocity = Vector2.ZERO
		player.set_physics_process(true)
		for key: int in keys:
			var event := InputEventKey.new()
			event.keycode = key
			event.pressed = true
			Input.parse_input_event(event)
		for i in 20: await physics_frame
		var speed := player.velocity.length()
		var displacement := player.position-Vector2(560,672)
		check(absf(speed-144.0)<0.01, "Non-normalized movement " + str(keys))
		for key: int in keys:
			var event := InputEventKey.new()
			event.keycode = key
			Input.parse_input_event(event)
		for i in 2: await physics_frame
		check(player.velocity.is_zero_approx(), "Did not stop after releasing " + str(keys))
		report.movement.append({"keys":str(keys),"speed":speed,"delta":str(displacement),"idle":str(player.sprite.animation)})
		player.set_physics_process(false)
	var camera := player.get_node("Camera2D") as Camera2D
	for p: Vector2 in [Vector2(560,576),Vector2(560,240),Vector2(560,936),Vector2(100,576),Vector2(1020,576),Vector2(250,380),Vector2(870,850)]:
		player.position = p
		camera.force_update_scroll()
		await process_frame
		var center := camera.get_screen_center_position()
		var half_view := camera.get_viewport_rect().size / camera.zoom * 0.5
		check(center.x-half_view.x>=31.9 and center.x+half_view.x<=1088.1 and center.y-half_view.y>=15.9 and center.y+half_view.y<=992.1,"Camera outside room at " + str(p))
		if p == Vector2(560,576):
			check(center.distance_to(p+Vector2(0,-24))<0.1,"Aelin not visually centered")
		report.camera.append({"player":str(p),"center":str(center),"size":str(half_view*2.0)})
	check(room.find_children("*", "Camera2D",true,false).size()==1, "Multiple cameras")
	check(room.get_node("Passagens").get_child_count()==8,"Missing door")
	for door in room.get_node("Passagens").get_children():
		check(not door.monitoring and door.get("cena_destino")=="","Active unfinished transition")
	check(room.get_node("ParedesFrente").z_index>player.z_index,"Foreground is behind player")
	check(room.get_node("Paredes").z_index==0,"All walls forced in front")
	report["failures"] = failures
	FileAccess.open(DOC+"testes_funcionais.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("TEST_RESULT perimeter=",report.perimeter.size()," pillars=",report.pillars.size()," movement=",report.movement.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
