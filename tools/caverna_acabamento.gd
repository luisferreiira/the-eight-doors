extends RefCounted
## Ajuste localizado das manchas de lajes; mantém os demais nós e recursos.
static func aplicar() -> void:
	var path = "res://scenes/world/environments/fase_caverna.tscn"
	var scene = load(path).instantiate()
	var layer = scene.get_node("TransicoesPiso")
	var atlas = layer.tile_set.get_source(90)
	# Grupos periféricos assimétricos, preservando centro e oito limiares.
	var patches = [[22,16,11],[25,16,6],[40,16,26],[44,17,31], [15,23,16],[18,25,21],[48,24,36],[50,27,41], [10,38,11],[13,40,26],[16,43,16],[48,39,21],[51,40,31], [22,48,36],[25,50,6],[39,49,41],[43,48,11], [26,24,31],[40,28,16],[25,39,26],[43,36,21]]
	for p in patches:
		for y in 4:
			for x in 4:
				var coord = Vector2i(p[2]+x,24+y)
				if atlas.has_tile(coord): layer.set_cell(Vector2i(p[0]+x,p[1]+y),90,coord)
	var text = FileAccess.get_file_as_string(path)
	var regex = RegEx.new()
	regex.compile('(?s)(\\[node name="TransicoesPiso"[^\\n]*\\n.*?)(tile_map_data = [^\\n]*)')
	var match = regex.search(text)
	assert(match != null)
	text = text.substr(0,match.get_start(2)) + 'tile_map_data = ' + var_to_str(layer.tile_map_data) + text.substr(match.get_end(2))
	var f = FileAccess.open(path,FileAccess.WRITE)
	f.store_string(text)
	f.close()
	print("Lajes: ",layer.get_used_cells().size()," células")
	scene.free()
