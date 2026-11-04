extends RefCounted
## Cada TileSet precisa de sua própria instância de TileSetAtlasSource.
func _init():
	var path = "res://scenes/world/environments/fase_caverna.tscn"
	var text = FileAccess.get_file_as_string(path)
	var start = text.find('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_fhl2n"]')
	var end = text.find('[sub_resource',start+1)
	var block = text.substr(start,end-start)
	for id in ["TileSet_3it3m", "TileSet_pvaac", "TileSet_mp0yv", "TileSet_t8gtw"]:
		var new_id = "AtlasRefino_" + id
		var header = '[sub_resource type="TileSet" id="%s"]' % id
		text = text.replace(header + '\nsources/90 = SubResource("TileSetAtlasSource_fhl2n")', block.replace("TileSetAtlasSource_fhl2n",new_id) + header + '\nsources/90 = SubResource("%s")' % new_id)
	var f = FileAccess.open(path,FileAccess.WRITE)
	f.store_string(text)
	f.close()
