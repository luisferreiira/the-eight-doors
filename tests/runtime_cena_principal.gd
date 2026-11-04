extends Node
## Executado somente por game_eval do MCP; nao faz parte da cena do jogo.
const DOC := "res://docs/history/cena_principal_2026-10-27/"

func run() -> Dictionary:
	var tree := get_tree()
	var room := tree.current_scene
	var player := room.get_node("Aelin") as CharacterBody2D
	var camera := player.get_node("Camera2D") as Camera2D
	var saved_position := player.position
	var result := {"movement":[],"camera":[],"doors":[],"failures":[]}
	result["window_mode"] = DisplayServer.window_get_mode()
	result["physical_size"] = str(DisplayServer.window_get_size())
	result["viewport"] = str(player.get_viewport_rect().size)
	result["scene"] = room.scene_file_path
	result["stretch_mode"] = ProjectSettings.get_setting("display/window/stretch/mode")
	result["stretch_aspect"] = ProjectSettings.get_setting("display/window/stretch/aspect")
	for keys in [[KEY_W],[KEY_S],[KEY_A],[KEY_D],[KEY_W,KEY_A],[KEY_W,KEY_D],[KEY_S,KEY_A],[KEY_S,KEY_D]]:
		player.position = Vector2(560,672)
		for i in 2: await tree.physics_frame
		for key: int in keys:
			var event := InputEventKey.new()
			event.keycode = key
			event.pressed = true
			Input.parse_input_event(event)
		Input.flush_buffered_events()
		var offsets := []
		for i in 20:
			await tree.physics_frame
			await tree.process_frame
			offsets.append((camera.get_screen_center_position()-player.global_position-Vector2(0,-24)).length())
		var speed := player.velocity.length()
		if absf(speed-144.0)>0.01: result.failures.append("speed " + str(keys))
		var delta := player.position-Vector2(560,672)
		for key: int in keys:
			var event := InputEventKey.new()
			event.keycode = key
			Input.parse_input_event(event)
		Input.flush_buffered_events()
		for i in 2: await tree.physics_frame
		result.movement.append({"keys":str(keys),"speed":speed,"delta":str(delta),"tracking_max_error":offsets.max()})
	var snapshots := {"centro":Vector2(560,640),"norte":Vector2(560,222),"sul":Vector2(560,936),"leste":Vector2(1020,576),"oeste":Vector2(100,576),"profundidade":Vector2(704,904)}
	for label in snapshots:
		player.position = snapshots[label]
		for i in 3: await tree.process_frame
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		var center := camera.get_screen_center_position()
		var half := player.get_viewport_rect().size/camera.zoom*0.5
		var inside := center.x-half.x>=31.9 and center.x+half.x<=1088.1 and center.y-half.y>=15.9 and center.y+half.y<=992.1
		if not inside: result.failures.append("camera " + label)
		result.camera.append({"label":label,"player":str(player.position),"screen_center":str(center),"within_limits":inside})
		player.get_viewport().get_texture().get_image().save_png(DOC+"mcp_"+label+".png")
	for door in room.get_node("Passagens").get_children():
		var direction: Vector2 = (door.position-Vector2(560,576)).normalized()
		player.position = door.position-direction*64.0
		player.set_physics_process(false)
		var hit := player.move_and_collide(direction*160.0)
		if hit == null: result.failures.append("door " + str(door.name))
		result.doors.append({"name":str(door.name),"blocked":hit!=null,"detector_active":door.monitoring})
		player.set_physics_process(true)
	player.position = saved_position
	player.velocity = Vector2.ZERO
	for i in 3: await tree.process_frame
	FileAccess.open(DOC+"testes_mcp_runtime.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	return result
