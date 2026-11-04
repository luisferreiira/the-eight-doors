@tool
extends Node2D
const Map = preload("res://scripts/world/mapa.gd")
## Alteração: a visão geral mostra as mesmas cenas individuais usadas pelo jogo.
const RoomScenes = preload("res://scripts/world/cenas_salas.gd")
@export_tool_button("Atualizar mapa") var atualizar: Callable = rebuild

func _ready() -> void:
	if Engine.is_editor_hint(): rebuild()

func rebuild() -> void:
	if not Engine.is_editor_hint(): return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var rooms := Map.create_rooms()
	for id: String in rooms:
		# Alteração: inclui objetos e alterações visuais exclusivos de cada sala.
		var room: Node2D = RoomScenes.SCENES[id].instantiate()
		room.name = id
		room.position = Map.origin(rooms[id])
		# O fundo original extrapola a sala; ocultá-lo evita encobrir vizinhas.
		room.get_node("Fundo").hide()
		room.get_node("Iluminacao").hide()
		add_child(room)
		var label := Label.new()
		label.text = id
		label.position = room.position + Vector2(470,540)
		label.add_theme_font_size_override("font_size",64)
		label.z_index = 100
		add_child(label)
		for direction: String in Map.DIRECTIONS:
			var door := room.get_node("Passagens/Porta_" + Map.NAMES[direction])
			var target: String = rooms[id].links.get(direction,"")
			door.get_node("GradeFechada").visible = target.is_empty()
			if target.is_empty() or id > target: continue
			var line := Line2D.new()
			line.width = 10
			line.default_color = Color.CYAN
			line.z_index = 100
			line.points = PackedVector2Array([room.position+Map.PORTALS[direction],Map.origin(rooms[target])+Map.PORTALS[Map.OPPOSITE[direction]]])
			add_child(line)
