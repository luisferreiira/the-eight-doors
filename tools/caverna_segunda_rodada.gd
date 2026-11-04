class_name CavernaSegundaRodada
extends RefCounted
## Edição pontual; não reempacota a cena nem altera recursos.
const PATH: String = "res://scenes/world/environments/fase_caverna.tscn"

static func aplicar() -> void:
	var text: String = FileAccess.get_file_as_string(PATH)
	var scene: Node = (load(PATH) as PackedScene).instantiate()
	var grade: TileMapLayer = scene.get_node("Grade") as TileMapLayer
	assert(grade.get_used_rect() in [Rect2i(31,30,8,8), Rect2i(29,28,12,12)], "Grade inesperada")
	for cell: Vector2i in grade.get_used_cells():
		grade.erase_cell(cell)
	# Preserva os dois tiles externos de cada lado; repete apenas o miolo.
	var mapping: Array[int] = [0,1,2,3,4,5,2,3,4,5,6,7]
	for y: int in 12:
		for x: int in 12:
			grade.set_cell(Vector2i(29+x,28+y),90,Vector2i(50+mapping[x],mapping[y]))
	var walls: TileMapLayer = scene.get_node("Paredes") as TileMapLayer
	# Recortes estreitos tinham a base quatro células abaixo da parede vizinha.
	var strips: Array[Vector2i] = [Vector2i(8,42),Vector2i(19,53),Vector2i(61,42),Vector2i(50,53),Vector2i(14,48),Vector2i(55,48)]
	for origin: Vector2i in strips:
		for y: int in 10:
			var cell: Vector2i = origin + Vector2i(0,y)
			var ac: Vector2i = walls.get_cell_atlas_coords(cell)
			if ac.x == 29 or ac.x == 31:
				walls.erase_cell(cell)
	# Reconecta os vãos com topo/base existentes, omitindo duas linhas transparentes
	# e duas linhas do corpo. Altura final seis células, sem deformar pixels.
	var rows: Array[int] = [2,3,4,5,8,9]
	for origin: Vector2i in strips:
		var atlas_x: int = 31 if origin.x in [8,19,14] else 29
		for y: int in rows.size():
			walls.set_cell(origin + Vector2i(0,y),90,Vector2i(atlas_x,13+rows[y]))
	for layer: TileMapLayer in [grade,walls]:
		var regex: RegEx = RegEx.new()
		regex.compile('(?s)(\\[node name="' + str(layer.name) + '"[^\\n]*\\n.*?)(tile_map_data = [^\\n]*)')
		var result: RegExMatch = regex.search(text)
		assert(result != null)
		text = text.substr(0,result.get_start(2)) + 'tile_map_data = ' + var_to_str(layer.tile_map_data) + text.substr(result.get_end(2))
	var output: FileAccess = FileAccess.open(PATH,FileAccess.WRITE)
	output.store_string(text)
	output.close()
	scene.free()
	print("Grade 8x8 -> 12x12; seis encaixes inferiores recompostos de 10 para 6 células de altura.")
