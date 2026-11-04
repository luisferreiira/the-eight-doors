extends SceneTree

func _initialize() -> void:
	call_deferred("_capturar")

func _capturar() -> void:
	root.size=Vector2i(1280,1088)
	var recurso := load("res://scenes/dungeon/sala_central_referencia.tscn") as PackedScene
	var sala := recurso.instantiate() as Node2D
	root.add_child(sala)
	for i: int in range(15): await process_frame
	await RenderingServer.frame_post_draw
	var imagem := root.get_texture().get_image()
	var erro := imagem.save_png("res://sala_central_render_godot.png")
	print("CAPTURA_GODOT ",erro," ",imagem.get_size())
	quit(erro)
