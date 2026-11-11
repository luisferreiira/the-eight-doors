@tool
extends Node2D
const Map = preload("res://scripts/world/mapa.gd")
## A visão geral tem nós persistidos; validar nunca reconstrói nem apaga suas edições.
@export_tool_button("Validar mapa") var validar: Callable = validate_map

## Compara as instâncias salvas com os dados usados pelo jogo.
func validate_map() -> void:
	var rooms := Map.create_rooms()
	var errors := Map.validate(rooms)
	for id: String in rooms:
		var room := get_node_or_null("Salas/" + id)
		if room == null:
			errors.append("Sala ausente na visão geral: " + id)
		elif room.position != Map.origin(rooms[id]):
			errors.append("Posição diferente do mapa: " + id)
	if errors.is_empty():
		print("Mapa válido: %s salas. Edite a cena de origem para alterar também o jogo." % rooms.size())
	else:
		push_error(str(errors))
