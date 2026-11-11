## Porta controla a conexão e a grade existente na cena, sem gerar elementos visuais.
extends Area2D
signal requested(door: Area2D, body: CharacterBody2D)
const Map = preload("res://scripts/world/mapa.gd")
@export var direcao: String = "Norte"
var direction: String = ""
var destination: String = ""
var entry_direction: String = ""
var opened: bool = false
var room_id: String = ""
## ID compartilhado entre as duas faces de uma conexão inicialmente fechada.
var blocked_id: String = ""
## A grade sobe antes de liberar a passagem; valores ajustáveis no Inspector.
@export var opening_duration := 0.65
@export var opening_height := 48.0
var opening := false

## Identifica a direção e conecta a detecção física à passagem existente.
func _ready() -> void:
	for key: String in Map.NAMES:
		if Map.NAMES[key] == direcao: direction = key
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_entered)

## Um destino pode existir enquanto a grade mantém a conexão fechada nas duas faces.
func configure(id: String, target: String, blocked: String = "", solved: bool = false) -> void:
	room_id = id
	destination = target
	entry_direction = Map.OPPOSITE[direction]
	blocked_id = blocked
	# O progresso pertence à partida e é restaurado nas duas faces do atalho.
	opened = not target.is_empty() and (blocked.is_empty() or solved)
	$PlanoDaPorta/BloqueioFechado/Forma.disabled = opened
	$GradeFechada.visible = not opened
	# A sobreposição acompanha o estado da mesma porta, sem duplicar colisões.
	var visual_grade := get_node_or_null("VisualEspecial/Grade") as Sprite2D
	if visual_grade != null:
		visual_grade.visible = not opened

## Anima somente a grade visível; a moldura e o bloqueio ficam intactos até o fim.
func open_passage() -> void:
	if opened or opening or destination.is_empty(): return
	opening = true
	var grade := get_node_or_null("VisualEspecial/Grade") as Sprite2D
	if grade == null: grade = $GradeFechada
	var tween := create_tween().set_parallel()
	tween.tween_property(grade, "position:y", grade.position.y - opening_height, opening_duration)
	tween.tween_property(grade, "modulate:a", 0.0, opening_duration)
	await tween.finished
	opened = true
	opening = false
	grade.hide()
	$GradeFechada.hide()
	$PlanoDaPorta/BloqueioFechado/Forma.set_deferred("disabled", true)

## Usa o marcador editável de chegada, preservando ajustes feitos no Inspector.
func spawn_position() -> Vector2:
	return $PontoEntradaFuturo.global_position

## Somente conexões abertas encaminham o personagem ao gerenciador de transição.
func _entered(body: Node2D) -> void:
	if opened and body is CharacterBody2D:
		requested.emit(self, body)
