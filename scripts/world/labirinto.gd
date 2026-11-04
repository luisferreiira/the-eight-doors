## Labirinto coordena o nó principal: mapa, sala-base, personagem, câmera e fade. Mantém o mesmo jogador nas trocas.
extends Node2D
signal room_changed(previous: String, current: String, entry: String)
const Map = preload("res://scripts/world/mapa.gd")
## Alteração: cada ID carrega sua cena visual própria, herdada da sala-base.
const RoomScenes = preload("res://scripts/world/cenas_salas.gd")
const CameraScript = preload("res://scripts/camera/camera_exploracao.gd")
@export var character_scene: PackedScene = preload("res://scenes/characters/players/aelin.tscn")
@export var random_spawn: bool = false
@export var spawn_seed: int = 0
var rooms: Dictionary = Map.create_rooms()
var player: CharacterBody2D
var camera: Camera2D
var room: Node2D
var current_room: String = ""
var transitioning: bool = false
var entry_lock: Area2D
var unlock_at: int = 0
var transition_count: int = 0
var validation_errors: Array[String] = []
var fade: CanvasLayer

## Valida o mapa, instancia o personagem exportado e sua câmera. Escolhe S01 ou sorteia somente salas seguras.
func _ready() -> void:
	add_to_group("gameplay")
	# Busca em runtime para permitir também preloads de cenas nos testes/tools.
	var state := get_node_or_null("/root/EstadoJogo")
	if state != null:
		state.configurar_tela(false)
		var selected_scene: PackedScene = state.cena_personagem()
		if selected_scene != null:
			character_scene = selected_scene
	fade = preload("res://scripts/effects/transicao_fade.gd").new()
	add_child(fade)
	validation_errors = Map.validate(rooms)
	# Adição: impede iniciar com uma sala do mapa sem cena visual cadastrada.
	for id: String in rooms:
		if not RoomScenes.SCENES.has(id):
			validation_errors.append("Sala sem cena visual: " + id)
	if not validation_errors.is_empty():
		push_error(str(validation_errors))
		return
	player = character_scene.instantiate()
	add_child(player)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.set_script(CameraScript)
	player.add_child(camera)
	var start := "S01"
	if random_spawn:
		var safe: Array[String] = []
		for id: String in rooms:
			if rooms[id].get("safe",false): safe.append(id)
		if not safe.is_empty():
			var rng := RandomNumberGenerator.new()
			if spawn_seed != 0: rng.seed = spawn_seed
			else: rng.randomize()
			start = safe[rng.randi_range(0,safe.size()-1)]
	load_room(start)

## Libera a porta de chegada somente após tempo mínimo, afastamento e saída da área.
func _physics_process(_delta: float) -> void:
	# Both time AND leaving the arrival area are required; no bounce-back loop.
	if is_instance_valid(entry_lock) and Time.get_ticks_msec() >= unlock_at:
		# Arrival markers sit 64 px inside; require an actual step farther inside.
		if player.global_position.distance_to(entry_lock.global_position) > 88.0 and not entry_lock.overlaps_body(player):
			entry_lock = null

## Recebe porta e corpo; rejeita destinos inválidos e concorrência antes de bloquear o movimento.
func request_transition(door: Area2D, body: CharacterBody2D) -> void:
	if transitioning or body != player or door == entry_lock or door.room_id != current_room or not door.opened: return
	if not rooms.has(door.destination) or rooms[current_room].links.get(door.direction,"") != door.destination: return
	transitioning = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	# Scene mutation is deferred out of physics query flushing.
	call_deferred("finish_transition", door.destination, door.entry_direction)

## Escurece antes de carregar o destino e a entrada oposta; revela antes de liberar os controles.
func finish_transition(target: String, entry: String) -> void:
	var previous := current_room
	await fade.escurecer()
	if not rooms.has(target) or not Map.OPPOSITE.has(entry):
		await fade.revelar()
		transitioning = false
		player.controls_enabled = true
		return
	load_room(target, entry)
	transition_count += 1
	await fade.revelar()
	transitioning = false
	player.controls_enabled = true
	room_changed.emit(previous,current_room,entry)

## Remove apenas a sala antiga. Reparenta o jogador persistente, configura portas, entrada e limites globais da câmera.
func load_room(id: String, entry: String = "") -> void:
	if is_instance_valid(room):
		player.reparent(self,true)
		remove_child(room)
		room.queue_free()
	# Alteração: preserva as edições feitas nos nós da cena individual no editor 2D.
	room = RoomScenes.SCENES[id].instantiate()
	add_child(room)
	room.configure(id,rooms[id])
	room.attach_player(player)
	current_room = id
	for door in room.doors.values(): door.requested.connect(request_transition)
	player.global_position = room.to_global(Map.CENTER_SPAWN) if entry.is_empty() else room.doors[entry].spawn_position()
	player.velocity = Vector2.ZERO
	entry_lock = null if entry.is_empty() else room.doors[entry]
	unlock_at = Time.get_ticks_msec()+250
	var bounds := Rect2(room.position+Map.CAMERA_BOUNDS.position,Map.CAMERA_BOUNDS.size)
	camera.limit_left = roundi(bounds.position.x)
	camera.limit_top = roundi(bounds.position.y)
	camera.limit_right = roundi(bounds.end.x)
	camera.limit_bottom = roundi(bounds.end.y)
	camera.reset_smoothing()
	camera.force_update_scroll()
	$HUD/Sala.text = "%s · %s · WASD · Esc: pausa" % [id, player.name]
