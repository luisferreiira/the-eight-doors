class_name TestFaseCavernaVisual
extends Node

func test_camadas_e_celulas_validas():
	var root = load("res://scenes/world/environments/fase_caverna.tscn").instantiate()
	for name in ["Fundo","Piso","Tunel","Paredes","Portas","Elementos","Camera2D"]:
		assert(root.has_node(NodePath(name)))
	assert(root.get_node("Fundo").texture == null)
	for n in root.get_children():
		if n is TileMapLayer:
			assert(n.tile_set.tile_size == Vector2i(16,16))
			assert(n.scale == Vector2.ONE)
			for cell in n.get_used_cells():
				var source = n.get_cell_source_id(cell)
				assert(n.tile_set.has_source(source), str(n.name))
				assert(n.tile_set.get_source(source).has_tile(n.get_cell_atlas_coords(cell)), str(n.name))
	root.free()

func test_composicao():
	var root = load("res://scenes/world/environments/fase_caverna.tscn").instantiate()
	var doors = root.get_node("Portas")
	# Oito âncoras verificadas no atlas nativo.
	for p in [Vector2i(30,2),Vector2i(30,50),Vector2i(-1,31),Vector2i(61,31)]:
		assert(doors.get_cell_source_id(p) == 90)
	var elements = root.get_node("Elementos")
	for p in [Vector2i(23,19),Vector2i(43,19),Vector2i(23,41),Vector2i(43,41)]:
		assert(elements.get_cell_atlas_coords(p) == Vector2i(45,0))
	var flames = 0
	for p in root.get_node("Tochas").get_used_cells():
		if root.get_node("Tochas").get_cell_atlas_coords(p) == Vector2i(59,0): flames += 1
	assert(flames == 8)
	assert(root.get_node("Grade").get_used_cells().size() == 144)
	assert(root.get_node("Grade").get_used_rect() == Rect2i(29,28,12,12))
	for p in root.get_node("Tunel").get_used_cells():
		assert(not Rect2i(25,24,20,20).has_point(p), "Túnel invadiu o centro")
	root.free()

func test_juncoes_inferiores() -> void:
	var root: Node = (load("res://scenes/world/environments/fase_caverna.tscn") as PackedScene).instantiate()
	var walls: TileMapLayer = root.get_node("Paredes") as TileMapLayer
	var rows: Array[int] = [2,3,4,5,8,9]
	var strips: Array[Vector2i] = [Vector2i(8,42),Vector2i(19,53),Vector2i(61,42),Vector2i(50,53),Vector2i(14,48),Vector2i(55,48)]
	for origin: Vector2i in strips:
		var atlas_x: int = 31 if origin.x in [8,19,14] else 29
		for y: int in 6:
			assert(walls.get_cell_atlas_coords(origin + Vector2i(0,y)) == Vector2i(atlas_x,13+rows[y]))
		for y: int in range(6,10):
			var ac: Vector2i = walls.get_cell_atlas_coords(origin + Vector2i(0,y))
			assert(ac.x != 29 and ac.x != 31, "Extensão inferior excedente")
	root.free()

func test_recursos_originais_preservados():
	var old = FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../arquivo-the-eight-doors/fase_caverna_backup_20260723_refino_atual.tscn.bak"))
	var paths: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/organizacao_manifesto.json"))
	for original in paths:
		old = old.replace("res://" + original, "res://" + paths[original])
	var current = FileAccess.get_file_as_string("res://scenes/world/environments/fase_caverna.tscn")
	old = old.replace("\r\n", "\n")
	current = current.replace("\r\n", "\n")
	var regex = RegEx.new()
	regex.compile('(?s)\\[sub_resource[^\\n]+\\].*?(?=\\n\\[|\\z)')
	for match in regex.search_all(old):
		var block = match.get_string().strip_edges()
		if block.begins_with('[sub_resource type="TileSet"'):
			# As únicas propriedades adicionadas são fontes; existentes continuam idênticas.
			for line in block.split('\n'):
				assert(current.contains(line), line)
		else:
			assert(current.contains(block), "Subrecurso original alterado")
	for line in old.split('\n'):
		if line.begins_with('[ext_resource'): assert(current.contains(line))
