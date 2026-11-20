## Sala controla o nó raiz da sala-base. Usa Mapa e as portas existentes, sem criar personagem ou câmera.
extends Node2D
const Map = preload("res://scripts/world/mapa.gd")
var room_id: String = ""
var doors: Dictionary = {}

## Indexa as portas e acrescenta um limite físico externo: mesmo durante bloqueios de transição ninguém sai para o vazio.
func _ready() -> void:
	for door in $Passagens.get_children(): doors[door.direction] = door

## Mantém uma barreira no perímetro, deixando somente o vão da saída externa livre.
func _build_safety_boundary() -> void:
	var previous := get_node_or_null("LimiteSeguro")
	if previous != null:
		previous.queue_free()
	var boundary := StaticBody2D.new()
	boundary.name = "LimiteSeguro"
	boundary.collision_layer = 1
	boundary.collision_mask = 2
	add_child(boundary)
	for index in Map.CONTOUR.size():
		var a: Vector2 = Map.CONTOUR[index]
		var b: Vector2 = Map.CONTOUR[(index+1)%Map.CONTOUR.size()]
		var segments: Array[PackedVector2Array] = [PackedVector2Array([a, b])]
		# As saídas externas ocupam o meio da borda oeste ou norte; preserva o restante do limite.
		var exit_direction: String = Map.EXITS.get(room_id, "")
		var is_exit_edge := (exit_direction == "O" and index == 6) or (exit_direction == "N" and index == 0)
		if is_exit_edge:
			var center := Vector2(64, 576) if exit_direction == "O" else Vector2(560, 192)
			var half_gap := 52.0
			var unit := (b-a).normalized()
			var gap_start := center - unit * half_gap
			var gap_end := center + unit * half_gap
			segments = [PackedVector2Array([a, gap_start]), PackedVector2Array([gap_end, b])]
		for segment in segments:
			var start: Vector2 = segment[0]
			var end: Vector2 = segment[1]
			var outward := (end-start).orthogonal().normalized()
			var shape := CollisionPolygon2D.new()
			shape.polygon = PackedVector2Array([start+outward*18,end+outward*18,end+outward*50,start+outward*50])
			boundary.add_child(shape)

## Reaplica os desafios resolvidos sem alterar os visuais definidos na cena.
func configure(id: String, config: Dictionary, solved: Dictionary = {}) -> void:
	room_id = id
	position = Map.origin(config)
	_build_safety_boundary()
	var blocked: Dictionary = config.get("blocked", {})
	for direction: String in doors:
		var challenge: String = blocked.get(direction, "")
		doors[direction].configure(id, config.links.get(direction, ""), challenge, solved.has(challenge))

## Reparenta o corpo existente para compartilhar a ordenação por Y com os pilares, preservando sua identidade.
func attach_player(player: CharacterBody2D) -> void:
	# The authored room and pillars use y-sort. Reparent the same persistent body.
	player.reparent(self, true)
