extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	var room := load("res://scenes/world/environments/sala_central_jogavel.tscn").instantiate() as Node2D
	root.add_child(room)
	var player := room.get_node("Aelin") as CharacterBody2D
	player.set_physics_process(false)
	var results := []
	var failures := []
	for size: Vector2i in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(1366,768),Vector2i(1280,1024)]:
		root.size = size
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		var logical := player.get_viewport_rect().size
		var stretch := player.get_screen_transform()
		var correct := logical.is_equal_approx(Vector2(640,360)) and absf(stretch.x.length()-stretch.y.length())<0.01
		if not correct: failures.append(str(size))
		results.append({"requested":str(size),"actual_window":str(root.size),"logical":str(logical),"stretch_x":stretch.x.length(),"stretch_y":stretch.y.length(),"proportional":correct})
	FileAccess.open("res://docs/history/cena_principal_2026-10-27/testes_resolucoes.json",FileAccess.WRITE).store_string(JSON.stringify({"samples":results,"failures":failures},"\t"))
	print("RESOLUTION_TEST ",JSON.stringify(results)," failures=",failures)
	quit(0 if failures.is_empty() else 1)
