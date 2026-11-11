extends SceneTree
func _initialize():
 var room=load("res://scenes/world/environments/sala_central_jogavel.tscn").instantiate()
 for name in ["Paredes","Molduras","Portas"]:
  var layer=room.get_node(name)
  var cells=[]
  for cell in layer.get_used_cells():
   if cell.y>=40:cells.append(str(cell))
  print(name," lower cells ",cells)
 room.free()
 quit()
