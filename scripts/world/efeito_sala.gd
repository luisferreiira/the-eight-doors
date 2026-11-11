extends Node2D
## Efeito e pista persistidos na cena; pedra é reconhecida nos TileMapLayers reais.
@export_enum("Chão falso:0", "Controles invertidos:1") var tipo: int = 1
@export_multiline var dica: String = ""

## Margem de dois pixels evita atalhos pela terra nas bordas.
func is_false_floor(point: Vector2) -> bool:
 if tipo != 0: return false
 var room = get_parent()
 for door in room.get_node("Passagens").get_children():
  if point.distance_to(door.spawn_position()) < 58: return false
 for offset in [Vector2.ZERO,Vector2(2,0),Vector2(-2,0),Vector2(0,2),Vector2(0,-2)]:
  for name in ["TransicoesPiso", "Piso"]:
   var layer: TileMapLayer = room.get_node(name)
   var cell = layer.local_to_map(layer.to_local(point + offset))
   var atlas = layer.get_cell_atlas_coords(cell)
   if layer.get_cell_source_id(cell) == 3 and atlas.y >= 24 and atlas.y <= 27 and atlas.x >= 6 and atlas.x < 44:
    return false
 return true
