extends RefCounted
## Correção de ordenação textual de subrecurso; não modifica a fonte.
func _init():
	var path = "res://scenes/world/environments/fase_caverna.tscn"
	var text = FileAccess.get_file_as_string(path)
	var start = text.find('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_fhl2n"]')
	var end = text.find('[sub_resource',start+1)
	assert(start > 0 and end > start)
	var block = text.substr(start,end-start)
	text = text.substr(0,start) + text.substr(end)
	var first = text.find('[sub_resource')
	text = text.substr(0,first) + block + text.substr(first)
	var f = FileAccess.open(path,FileAccess.WRITE)
	f.store_string(text)
	f.close()
