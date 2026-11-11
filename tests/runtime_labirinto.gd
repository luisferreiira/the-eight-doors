extends RefCounted
const Map = preload("res://scripts/world/mapa.gd")
const OUT := "res://docs/history/expansao_2026-10-30/"

func run(game: Node2D, selected: String = "") -> Dictionary:
	var results := {"transitions":[],"failures":[]}
	if not game.has_method("load_room"):
		return {"failures":["Abra a cena labirinto.tscn antes do teste."]}
	var tree := game.get_tree()
	game.load_room("S01")
	await tree.create_timer(0.1).timeout
	await capture(game,"centro")
	## Expansão: E0 segue fechado; inclui as novas conexões oeste e noroeste.
	for direction: String in ["N","NE","S","SO","O","NO"]:
		if not selected.is_empty() and direction != selected: continue
		var target: String = game.rooms.S01.links[direction]
		for step in 2:
			var travel: String = direction if step==0 else Map.OPPOSITE[direction]
			var expected: String = target if step==0 else "S01"
			var previous: String = game.current_room
			var door: Area2D = game.room.doors[travel]
			var normal := Vector2(Map.DIRECTIONS[travel]).normalized()
			game.player.global_position = door.global_position-normal*144
			game.entry_lock = null
			await tree.create_timer(0.08).timeout
			if step==0: await capture(game,"porta_"+travel)
			var keys := []
			if normal.x<0: keys.append(KEY_A)
			if normal.x>0: keys.append(KEY_D)
			if normal.y<0: keys.append(KEY_W)
			if normal.y>0: keys.append(KEY_S)
			for key: int in keys:
				var event := InputEventKey.new()
				event.keycode = key as Key
				event.pressed = true
				Input.parse_input_event(event)
			var ticks := 0
			while (game.current_room==previous or game.transitioning) and ticks<240:
				await tree.physics_frame
				ticks += 1
			for key: int in keys:
				var event := InputEventKey.new()
				event.keycode = key as Key
				Input.parse_input_event(event)
			await tree.create_timer(0.08).timeout
			var ok: bool = game.current_room==expected
			results.transitions.append({"from":previous,"direction":travel,"to":game.current_room,"ok":ok,"ticks":ticks})
			if not ok:
				results.failures.append(previous+travel)
				return results
			if step==0: await capture(game,"entrada_"+target)
	game.load_room("S01")
	game.player.position = Vector2(992,576)
	await tree.create_timer(0.1).timeout
	await capture(game,"porta_fechada_L")
	game.player.position = Map.CENTER_SPAWN
	game.entry_lock = null
	FileAccess.open(OUT+"testes_mcp_runtime"+selected+".json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	return results

func capture(game: Node2D, label: String) -> void:
	game.camera.force_update_scroll()
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(OUT+label+".png")
