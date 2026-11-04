extends SceneTree
const DOC := "res://docs/history/cena_principal_2026-10-27/"
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var room := load("res://scenes/world/environments/sala_central_jogavel.tscn").instantiate() as Node2D
	root.add_child(room)
	var player := room.get_node("Aelin") as CharacterBody2D
	player.set_physics_process(false)
	player.get_node("AnimatedSprite2D").stop()
	var camera := player.get_node("Camera2D") as Camera2D
	var positions := {"centro":Vector2(560,640),"norte":Vector2(560,222),"sul":Vector2(560,936),"leste":Vector2(1020,576),"oeste":Vector2(100,576),"profundidade":Vector2(632,908),"oclusao_completa":Vector2(632,940),"nordeste":Vector2(870,378),"sudoeste":Vector2(250,774)}
	for label in positions:
		player.position = positions[label]
		camera.force_update_scroll()
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(DOC+"depois_"+label+".png")
		if label == "profundidade":
			for node in ["ParedesFrente","MoldurasFrente","PortasFrente"]: room.get_node(node).visible = false
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(DOC+"comparacao_sem_frente.png")
			for node in ["ParedesFrente","MoldurasFrente","PortasFrente"]: room.get_node(node).visible = true
	print("CAPTURAS_OK")
	quit()
