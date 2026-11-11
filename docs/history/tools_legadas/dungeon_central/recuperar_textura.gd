extends SceneTree
func _initialize() -> void:
	var tex := CompressedTexture2D.new()
	var err := tex.load("res://.godot/imported/preview_murinho.png-8523b09794c5ce865ddbcafb86760485.ctex")
	if err != OK:
		push_error("Cannot recover texture: " + str(err))
		quit(1)
		return
	var image := tex.get_image()
	var dest := "res://assets/environments/generated/dungeon_central/refino/murinho_recuperado.png"
	err = image.save_png(dest)
	print("RECOVER_TEXTURE ", err, " size ", image.get_size())
	quit(err)

