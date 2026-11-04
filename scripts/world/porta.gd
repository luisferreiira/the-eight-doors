## Porta controla cada Area2D da base. Usa direções do Mapa e emite requested para Labirinto; não troca salas sozinha.
extends Area2D
## One controller for all eight existing door models.
signal requested(door: Area2D, body: CharacterBody2D)
const Map = preload("res://scripts/world/mapa.gd")
@export var direcao: String = "Norte"
var direction: String = ""
var destination: String = ""
var entry_direction: String = ""
var opened: bool = false
var room_id: String = ""
var glow: Line2D

## Identifica a direção, conecta a detecção física e cria o selo discreto sem novos sprites.
func _ready() -> void:
	for key: String in Map.NAMES:
		if Map.NAMES[key] == direcao: direction = key
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_entered)
	# Use the existing grade; the subtle seal is a drawn line, no new sprite.
	glow = Line2D.new()
	glow.name = "SeloMagico"
	glow.z_index = 6
	glow.width = 3.0
	glow.default_color = Color(0.46,0.65,1.0,0.5)
	glow.material = CanvasItemMaterial.new()
	glow.material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var tangent := Vector2(Map.DIRECTIONS[direction]).normalized().orthogonal()
	var inward := -Vector2(Map.DIRECTIONS[direction]).normalized()
	glow.points = PackedVector2Array([-tangent*38 + inward*12,tangent*38 + inward*12])
	add_child(glow)

## Recebe origem e destino. Calcula a entrada oposta e sincroniza grade, selo e colisão com o estado aberto.
func configure(id: String, target: String) -> void:
	room_id = id
	destination = target
	entry_direction = Map.OPPOSITE[direction]
	opened = not target.is_empty()
	$PlanoDaPorta/BloqueioFechado/Forma.disabled = opened
	$GradeFechada.visible = not opened
	glow.visible = not opened

## Retorna a posição global do marcador interno de chegada, usada após carregar a sala.
func spawn_position() -> Vector2:
	return $PontoEntradaFuturo.global_position

## Encaminha apenas corpos de personagem detectados em portas abertas ao gerenciador.
func _entered(body: Node2D) -> void:
	if opened and body is CharacterBody2D:
		requested.emit(self, body)
