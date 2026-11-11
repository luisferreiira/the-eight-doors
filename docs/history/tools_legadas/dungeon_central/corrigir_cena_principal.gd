extends SceneTree
## Migracao offline repetivel: sempre parte do backup de 27/10, nunca da referencia.
var BACKUP := ProjectSettings.globalize_path("res://").path_join("../arquivo-the-eight-doors/backups/cena_principal_2026-10-27/scenes__dungeon__sala_central_jogavel.tscn.bak")
const OUTPUT := "res://scenes/world/environments/sala_central_jogavel.tscn"
const DOC := "res://docs/history/cena_principal_2026-10-27/"
var audit: Dictionary = {}

func _initialize() -> void:
	call_deferred("build")

func own(node: Node, scene: Node) -> void:
	node.owner = scene
	for child in node.get_children():
		own(child, scene)

func rectangle(parent: Node, node_name: String, size: Vector2, at: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 2
	parent.add_child(body)
	var shape := CollisionShape2D.new()
	shape.name = "Forma"
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)

func build() -> void:
	var source := FileAccess.get_file_as_string(BACKUP)
	FileAccess.open("user://cena_principal_antes.tscn", FileAccess.WRITE).store_string(source)
	var packed_source := load("user://cena_principal_antes.tscn") as PackedScene
	if packed_source == null:
		quit(1)
		return
	var room := packed_source.instantiate() as Node2D
	# Configure before adding to tree so the old camera script never runs.
	var player := room.get_node("Aelin") as CharacterBody2D
	player.position = Vector2(560, 640)
	var camera := player.get_node("Camera2D") as Camera2D
	camera.set_script(load("res://scripts/camera/camera_exploracao.gd"))
	camera.position = Vector2(0, -24)
	camera.zoom = Vector2.ONE
	camera.limit_left = 32
	camera.limit_top = 16
	camera.limit_right = 1088
	camera.limit_bottom = 992
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	root.add_child(room)
	room.set_meta("versao_jogavel", "2026-10-27")
	audit["tile_layers"] = []
	for node in room.find_children("*", "TileMapLayer", true, false):
		var layer := node as TileMapLayer
		audit["tile_layers"].append({"name":str(layer.name), "cells":layer.get_used_cells().size(), "physics_layers":layer.tile_set.get_physics_layers_count()})
		# Collision is authored explicitly below; art must not create hidden bodies.
		layer.collision_enabled = false
	# Remove protruding floor and trim; the door recess stays within the wall line.
	var removed := 0
	for layer_name in ["Piso", "TransicoesPiso", "Tunel"]:
		var layer := room.get_node(layer_name) as TileMapLayer
		for cell: Vector2i in layer.get_used_cells():
			var p := layer.map_to_local(cell)
			if p.x < 48 or p.x > 1072:
				layer.erase_cell(cell)
				removed += 1
	audit["exterior_floor_cells_removed"] = removed
	# Only the southern architectural pieces overlap the player from the front.
	audit["foreground_cells"] = {}
	for layer_name in ["Paredes", "Molduras", "Portas"]:
		var back := room.get_node(layer_name) as TileMapLayer
		var front := TileMapLayer.new()
		front.name = layer_name + "Frente"
		front.tile_set = back.tile_set
		front.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		front.z_index = 4
		front.collision_enabled = false
		room.add_child(front)
		front.owner = room
		for cell: Vector2i in back.get_used_cells():
			if back.map_to_local(cell).y >= 704:
				front.set_cell(cell, back.get_cell_source_id(cell), back.get_cell_atlas_coords(cell), back.get_cell_alternative_tile(cell))
				back.erase_cell(cell)
		audit["foreground_cells"][str(front.name)] = front.get_used_cells().size()
	# Normalize collision transforms and layers. Retain the hand-authored wall geometry.
	var walls := room.get_node("Colisoes") as StaticBody2D
	walls.collision_layer = 1
	walls.collision_mask = 2
	for wall in walls.get_children():
		wall.position = Vector2.ZERO
		wall.scale = Vector2.ONE
	for column in room.get_node("Elementos/Colunas").get_children():
		column.collision_layer = 1
		column.collision_mask = 2
		column.y_sort_enabled = false
	for torch in room.get_node("TochasFora").get_children():
		if torch.position.y >= 704:
			torch.z_index = 6
	for web in room.get_node("Elementos/Teias").get_children():
		if web.position.y >= 704:
			web.z_index = 2
	# Retire the protruding lateral corridors and misplaced jamb instances.
	var old_doors := room.get_node("Passagens")
	room.remove_child(old_doors)
	old_doors.free()
	var doors := Node2D.new()
	doors.name = "Passagens"
	room.add_child(doors)
	var directions := ["Norte", "Nordeste", "Leste", "Sudeste", "Sul", "Sudoeste", "Oeste", "Noroeste"]
	var markers := ["SaidaN", "SaidaNE", "SaidaL", "SaidaSE", "SaidaS", "SaidaSO", "SaidaO", "SaidaNO"]
	var normals := [Vector2.UP, Vector2(1,-1).normalized(), Vector2.RIGHT, Vector2.ONE.normalized(), Vector2.DOWN, Vector2(-1,1).normalized(), Vector2.LEFT, Vector2(-1,-1).normalized()]
	audit["doors"] = []
	for i in directions.size():
		var door := Area2D.new()
		door.name = "Porta_" + directions[i]
		door.position = room.get_node("Entradas/" + markers[i]).position
		door.set_script(load("res://scripts/world/passagem_preparada.gd"))
		door.set("direcao", directions[i])
		door.monitoring = false
		door.monitorable = false
		door.collision_layer = 0
		door.collision_mask = 2
		doors.add_child(door)
		var zone := CollisionShape2D.new()
		zone.name = "ZonaDeteccaoInativa"
		var zone_box := RectangleShape2D.new()
		zone_box.size = Vector2(112, 48)
		zone.shape = zone_box
		zone.position = -normals[i] * 28.0
		zone.rotation = normals[i].angle() + PI / 2.0
		door.add_child(zone)
		var blocker := Node2D.new()
		blocker.name = "PlanoDaPorta"
		blocker.rotation = normals[i].angle() + PI / 2.0
		door.add_child(blocker)
		rectangle(blocker, "BloqueioFechado", Vector2(112, 28), Vector2.ZERO)
		var spawn := Marker2D.new()
		spawn.name = "PontoEntradaFuturo"
		spawn.position = -normals[i] * 64.0
		door.add_child(spawn)
		var grate := Sprite2D.new()
		grate.name = "GradeFechada"
		var iron := AtlasTexture.new()
		iron.atlas = load("res://assets/environments/generated/dungeon_central/atlas_sala_central.png")
		iron.region = Rect2(816, 16, 96, 96)
		grate.texture = iron
		grate.position = Vector2(0, -64)
		grate.scale = Vector2(0.67, 0.83)
		grate.z_index = 5
		if i in [1,3,5,7]:
			# Upright iron bars; the horizontal axis follows the diagonal door sill.
			var slope := 0.5 if i in [1,5] else -0.5
			grate.transform = Transform2D(Vector2(0.5,slope),Vector2(0,0.83),Vector2(0,-48))
		door.add_child(grate)
		if directions[i] in ["Leste", "Oeste"]:
			grate.scale = Vector2(0.25, 0.83)
			grate.position = Vector2(0,-8)
			for p in [Vector2(-16,-128), Vector2(-16,32)]:
				var jamb := Sprite2D.new()
				jamb.name = "BatenteSuperior" if p.y < 0 else "BatenteInferior"
				jamb.position = p
				jamb.centered = false
				jamb.z_index = 5
				var tex := AtlasTexture.new()
				tex.atlas = load("res://assets/environments/mapa/The_Eight_Doors_Tiles_Preparados/atlas_complementar_C.png")
				tex.region = Rect2(16,48,36,92)
				jamb.texture = tex
				door.add_child(jamb)
		audit["doors"].append({"direction":directions[i], "position":[door.position.x,door.position.y], "monitoring":false})
	own(doors, room)
	var atmosphere := CanvasLayer.new()
	atmosphere.name = "Atmosfera"
	atmosphere.layer = 10
	room.add_child(atmosphere)
	var vignette := ColorRect.new()
	vignette.name = "Vinheta"
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/vinheta.gdshader")
	vignette.material = material
	atmosphere.add_child(vignette)
	own(atmosphere, room)
	var packed := PackedScene.new()
	assert(packed.pack(room) == OK)
	assert(ResourceSaver.save(packed, OUTPUT) == OK)
	FileAccess.open(DOC + "auditoria_migracao.json", FileAccess.WRITE).store_string(JSON.stringify(audit, "\t"))
	print("CORRECAO_CENA_OK ", JSON.stringify(audit))
	quit()
