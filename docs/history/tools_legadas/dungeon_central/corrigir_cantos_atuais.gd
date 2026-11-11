extends SceneTree
func _initialize():
 var path="res://scenes/world/environments/sala_central_jogavel.tscn"
 var room=load(path).instantiate()
 var report={}
 for name in ["Paredes","Portas"]:
  var source=room.get_node(name)
  var front=room.get_node(name+"Frente")
  var moved=[]
  for cell in source.get_used_cells():
   if cell.y >= (40 if name=="Paredes" else 43):
    if front.get_cell_source_id(cell)!=-1:
     push_error("Overlapping tile; migration aborted")
     quit(1)
     return
    front.set_cell(cell,source.get_cell_source_id(cell),source.get_cell_atlas_coords(cell),source.get_cell_alternative_tile(cell))
    source.erase_cell(cell)
    moved.append(str(cell))
  report[name]=moved
 var packed=PackedScene.new()
 assert(packed.pack(room)==OK)
 assert(ResourceSaver.save(packed,path)==OK)
 FileAccess.open("res://docs/history/animacoes_visual_20261027/tiles_transferidos.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print(JSON.stringify(report))
 room.free()
 quit()
