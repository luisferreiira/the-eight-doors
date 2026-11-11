extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1400,1104)
	var room := (load("res://scenes/world/environments/sala_central_jogavel.tscn") as PackedScene).instantiate()
	root.add_child(room)
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var err := image.save_png("res://docs/history/dungeon_jogavel/sala_jogavel.png")
	print("CAPTURE ",err)
	quit(err)
