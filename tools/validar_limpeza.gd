extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var failures: Array[String] = []
	for path in ["res://scenes/characters/players/aelin.tscn", "res://scenes/characters/players/dorian.tscn", "res://scenes/world/environments/sala_central_jogavel.tscn"]:
		var scene = load(path)
		if not scene is PackedScene:
			failures.append("Load: " + path)
			continue
		var instance = scene.instantiate()
		if instance == null:
			failures.append("Instantiate: " + path)
			continue
		root.add_child(instance)
		await process_frame
		if path.contains("players/"):
			var sprite = instance.get_node("AnimatedSprite2D") as AnimatedSprite2D
			for anim in sprite.sprite_frames.get_animation_names():
				for i in sprite.sprite_frames.get_frame_count(anim):
					var texture = sprite.sprite_frames.get_frame_texture(anim, i)
					if texture == null or texture.get_width() == 0:
						failures.append(path + " texture " + anim)
		print("LOADED ", path)
		instance.queue_free()
		await process_frame
	print("CLEANUP_VALIDATION ", JSON.stringify({"failures":failures,"count":failures.size()}))
	quit(0 if failures.is_empty() else 1)
