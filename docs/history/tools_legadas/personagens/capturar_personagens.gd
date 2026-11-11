extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(896,400)
	root.content_scale_size = Vector2i(896,400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for i in 3: await process_frame
	var canvas := Node2D.new()
	root.add_child(canvas)
	var background := ColorRect.new()
	background.size = root.size
	background.color = Color("201e28")
	canvas.add_child(background)
	for row in 2:
		var who := "aelin" if row == 0 else "dorian"
		var directions := ["costas","frente","esquerda","direita"]
		for col in 4:
			var player := (load("res://scenes/players/" + who + ".tscn") as PackedScene).instantiate()
			canvas.add_child(player)
			player.set_physics_process(false)
			player.position = Vector2(112+col*224,170+row*200)
			player.scale = Vector2(2,2)
			player.get_node("AnimatedSprite2D").play("correndo_" + directions[col])
			var label := Label.new()
			label.text = who.capitalize() + " / " + directions[col]
			label.position = Vector2(24+col*224,12+row*200)
			canvas.add_child(label)
	for i in 24: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/history/dungeon_jogavel/personagens_godot.png")
	print("CHARACTERS_CAPTURE_OK")
	quit()

