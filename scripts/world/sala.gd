## Sala controla o nó raiz da sala-base. Usa Mapa e as portas existentes, sem criar personagem ou câmera.
extends Node2D
const Map = preload("res://scripts/world/mapa.gd")
var room_id: String = ""
var doors: Dictionary = {}

## Indexa as portas e acrescenta um limite físico externo: mesmo durante bloqueios de transição ninguém sai para o vazio.
func _ready() -> void:
	for door in $Passagens.get_children(): doors[door.direction] = door
	# Last-resort boundary beyond the transition zones, including open doors.
	# Keeps a player inside even if transition is locked or held against a doorway.
	var boundary := StaticBody2D.new()
	boundary.name = "LimiteSeguro"
	boundary.collision_layer = 1
	boundary.collision_mask = 2
	add_child(boundary)
	for index in Map.CONTOUR.size():
		var a: Vector2 = Map.CONTOUR[index]
		var b: Vector2 = Map.CONTOUR[(index+1)%Map.CONTOUR.size()]
		var outward := (b-a).orthogonal().normalized()
		var shape := CollisionPolygon2D.new()
		shape.polygon = PackedVector2Array([a+outward*18,b+outward*18,b+outward*50,a+outward*50])
		boundary.add_child(shape)

## Reaplica os desafios resolvidos sem alterar os visuais definidos na cena.
func configure(id: String, config: Dictionary, solved: Dictionary = {}) -> void:
	room_id = id
	position = Map.origin(config)
	var blocked: Dictionary = config.get("blocked", {})
	for direction: String in doors:
		var challenge: String = blocked.get(direction, "")
		doors[direction].configure(id, config.links.get(direction, ""), challenge, solved.has(challenge))

## Reparenta o corpo existente para compartilhar a ordenação por Y com os pilares, preservando sua identidade.
func attach_player(player: CharacterBody2D) -> void:
	# The authored room and pillars use y-sort. Reparent the same persistent body.
	player.reparent(self, true)
