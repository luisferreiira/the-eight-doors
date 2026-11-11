extends RefCounted
## Aplicação única e localizada: mantém todos os subrecursos e fontes originais.
const PATH = "res://scenes/world/environments/fase_caverna.tscn"
var BACKUP = ProjectSettings.globalize_path("res://").path_join("../arquivo-the-eight-doors/fase_caverna_backup_20260723_refino_atual.tscn.bak")

func _init() -> void:
	assert(FileAccess.file_exists(BACKUP))
	var text = FileAccess.get_file_as_string(PATH)
	assert(not text.contains("metadata/refino_modular"), "Refino já aplicado")
	var scene = load(PATH).instantiate()
	var atlas = scene.get_node("Portas").tile_set.get_source(4)
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environments/generated/dungeon_central/atlas_manifesto.json"))
	# Acrescentar uma fonte, sem substituir qualquer TileSet ou suas fontes.
	for id in ["TileSet_3it3m", "TileSet_pvaac", "TileSet_mp0yv", "TileSet_t8gtw", "TileSet_0qvm5"]:
		var header = '[sub_resource type="TileSet" id="%s"]' % id
		text = text.replace(header, header + '\nsources/90 = SubResource("TileSetAtlasSource_fhl2n")')
	var layers = manifest.layers.duplicate(true)
	layers["Grade"] = []
	layers["Tochas"] = []
	var elements = []
	for item in layers.Elementos:
		if item.name == "grade_central": layers.Grade.append(item)
		elif item.name == "tocha": layers.Tochas.append(item)
		else: elements.append(item)
	layers.Elementos = elements
	var z = {"Piso": -9, "TransicoesPiso": -8, "Entulho": -7, "Tunel": -6, "Paredes": 0, "Molduras": 1, "Portas": 2, "SombrasElementos": 3, "Grade": 4, "Elementos": 5, "Tochas": 6}
	for layer_name in layers:
		var layer = TileMapLayer.new()
		layer.tile_set = scene.get_node("Portas").tile_set
		# Recortes compostos são expandidos em células nativas 16x16 editáveis.
		for item in layers[layer_name]:
			var r = manifest.sprites[item.name].atlas
			for y in int(r[3]):
				for x in int(r[2]):
					var ac = Vector2i(int(r[0])+x, int(r[1])+y)
					if atlas.has_tile(ac):
						layer.set_cell(Vector2i(int(item.cell[0])+x,int(item.cell[1])+y),4,ac)
		var bytes = layer.tile_map_data
		# Source 4 -> 90 through native API, rather than relying on binary layout.
		var ts = layer.tile_set.duplicate()
		ts.add_source(atlas,90)
		layer.tile_set = ts
		for cell in layer.get_used_cells(): layer.set_cell(cell,90,layer.get_cell_atlas_coords(cell))
		bytes = layer.tile_map_data
		var data = 'tile_map_data = ' + var_to_str(bytes)
		if scene.has_node(NodePath(layer_name)):
			var regex = RegEx.new()
			regex.compile('(?s)(\\[node name="' + layer_name + '"[^\\n]*\\n)(.*?)(?=\\n\\[node|\\z)')
			var result = regex.search(text)
			assert(result != null)
			var body = result.get_string(2)
			var props = RegEx.new()
			props.compile('(?m)^(tile_map_data|visible|z_index) = .*\\n?')
			body = props.sub(body, "", true)
			text = text.replace(result.get_string(),result.get_string(1) + 'z_index = %d\n' % z[layer_name] + data + '\n' + body)
		else:
			text += '\n[node name="%s" type="TileMapLayer" parent="."]\nz_index = %d\n%s\ntile_set = SubResource("TileSet_0qvm5")\n' % [layer_name,z[layer_name],data]
		print(layer_name, ": ", layer.get_used_cells().size(), " células")
		layer.free()
	# Fundo é apenas uma cor; a referência não é renderizada.
	var start = text.find('[node name="Fundo"')
	var end = text.find('\n[node ',start+1)
	text = text.substr(0,start) + '[node name="Fundo" type="Polygon2D" parent="." unique_id=678136526]\nz_index = -10\ncolor = Color(0.025, 0.023, 0.031, 1)\npolygon = PackedVector2Array(-2000, -2000, 3000, -2000, 3000, 3000, -2000, 3000)\n' + text.substr(end)
	text = text.replace('[node name="fase_caverna" type="Node2D" unique_id=998825830]', '[node name="fase_caverna" type="Node2D" unique_id=998825830]\ntexture_filter = 1\nmetadata/refino_modular = true')
	text += '\n[node name="Camera2D" type="Camera2D" parent="."]\nposition = Vector2(560, 512)\nzoom = Vector2(0.6, 0.6)\n'
	var output = FileAccess.open(PATH,FileAccess.WRITE)
	output.store_string(text)
	output.close()
	scene.free()
	print("Aplicadas apenas propriedades dos nós e fontes adicionais. Subrecursos preservados.")

