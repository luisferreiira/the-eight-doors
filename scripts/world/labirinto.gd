## Labirinto coordena o nó principal: mapa, sala-base, personagem, câmera e fade. Mantém o mesmo jogador nas trocas.
extends Node2D
signal room_changed(previous: String, current: String, entry: String)
const Map = preload("res://scripts/world/mapa.gd")
## Alteração: cada ID carrega sua cena visual própria, herdada da sala-base.
const RoomScenes = preload("res://scripts/world/cenas_salas.gd")
const CameraScript = preload("res://scripts/camera/camera_exploracao.gd")
@export var character_scene: PackedScene = preload("res://scenes/characters/players/aelin.tscn")
## Novas partidas sorteiam um dos três inícios; desative para testar a S01.
@export var random_spawn: bool = true
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

## Painel compartilhado pela inscrição de E0 e pelo fluxo de vitória existente.
const INTERACTION_RANGE := 70.0
var seal_panel: CanvasLayer
var escaped := false
## Estado exclusivo da partida: erros são compartilhados pelas duas faces de cada porta.
var finished := false
var lives := 3
var score := 0
var challenge_errors: Dictionary = {}
var fall_count := 0
var notice := ""
## Avisos temporários compartilham o pergaminho, deixando o topo só para o status.
var notice_until := 0
var interaction_label: Label
var hint_scroll: TextureRect
## Primeiro desafio: E0 compartilha progresso entre S01/leste e S04/oeste.
const FIRST_CHALLENGE := "E0"
const STONE_SOLUTION: Array[String] = ["Estrela", "Lua", "Sol"]
var solved_challenges: Dictionary = {}
var active_challenge: Area2D
var unlocking := false
## A inversão e sua pista são lidas da cena da sala atual.
var room_effect: Node2D
## Recuperação guarda a entrada da visita e bloqueia ações durante a queda.
var falling := false
var return_position := Vector2.ZERO
var return_entry: Area2D

## Valida o mapa e inicia na sala sorteada, mantendo o personagem escolhido no menu.
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
	# Referências às instâncias editáveis presentes na cena do labirinto.
	seal_panel = $PainelSelo
	# Os quatro painéis direcionais compartilham o fluxo de abertura das grades.
	for id in ["D3", "D7", "D8", "D9"]:
		get_node(id).confirmed.connect(_confirm_challenge)
		get_node(id).dismissed.connect(_close_challenge)
	# Conecta o painel editável ao desafio da porta próxima.
	seal_panel.confirmed.connect(_confirm_challenge)
	seal_panel.dismissed.connect(_close_challenge)
	hint_scroll = $HUD/Pergaminho
	interaction_label = hint_scroll.get_node("Texto")
	# Dicas de navegação serão implementadas em outra etapa.
	interaction_label.text = ""
	hint_scroll.hide()
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
	load_room(choose_start_room())
	# Resultado persistido na cena atende vitória e derrota.
	$Resultado.hide()
	var actions = $Resultado/Overlay/Centro/Moldura/Conteudo/Acoes
	actions.get_node("Reiniciar").pressed.connect(func(): get_tree().reload_current_scene())
	actions.get_node("Menu").pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/menus/MenuInicial.tscn"))
	_refresh_score()

## Sorteio uniforme independente: cada início tem 1/3 de chance, podendo se repetir.
## Semente diferente de zero reproduz a escolha para testes no Inspector.
func choose_start_room() -> String:
	if not random_spawn: return "S01"
	var rng := RandomNumberGenerator.new()
	if spawn_seed != 0: rng.seed = spawn_seed
	else: rng.randomize()
	return Map.START_ROOMS[rng.randi_range(0, Map.START_ROOMS.size() - 1)]

## Libera a porta de chegada somente após tempo mínimo, afastamento e saída da área.
func _physics_process(_delta: float) -> void:
	# Both time AND leaving the arrival area are required; no bounce-back loop.
	if is_instance_valid(entry_lock) and Time.get_ticks_msec() >= unlock_at:
		# Arrival markers sit 64 px inside; require an actual step farther inside.
		if player.global_position.distance_to(entry_lock.global_position) > 88.0 and not entry_lock.overlaps_body(player):
			entry_lock = null
	# O HUD indica a inscrição ou a saída somente dentro do alcance de interação.
	if is_instance_valid(player) and is_instance_valid(room):
		_update_interaction_hint()
		hint_scroll.visible = not interaction_label.text.is_empty()
		# Consulta os tiles sob os pés somente durante exploração livre.
		if not blocks_pause() and not finished and is_instance_valid(room_effect) and room_effect.is_false_floor(player.global_position):
			falling = true
			_lock_player()
			call_deferred("_recover_from_fall")

## Queda visual preserva a escala editada e recupera na entrada segura.
func _recover_from_fall() -> void:
	var visual = player.get_node("AnimatedSprite2D")
	var original_scale: Vector2 = visual.scale
	var original_color: Color = visual.modulate
	var tween = create_tween()
	tween.tween_property(visual, "scale", original_scale * 0.08, 0.4)
	tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.4)
	await tween.finished
	player.global_position = return_position
	entry_lock = return_entry
	unlock_at = Time.get_ticks_msec() + 250
	visual.scale = original_scale
	visual.modulate = original_color
	camera.reset_smoothing()
	await get_tree().create_timer(0.2).timeout
	falling = false
	# Primeira queda avisa; as seguintes custam uma vida em qualquer sala.
	fall_count += 1
	if fall_count == 1:
		notice = "Primeira queda sem dano. As próximas custam 1 vida."
	else:
		_lose_life("A queda custou uma vida.")
	_refresh_score()
	player.controls_enabled = not finished

## E examina a primeira inscrição ou ativa a saída; Esc cancela o enigma.
func _unhandled_input(event: InputEvent) -> void:
	if finished or transitioning or unlocking or falling or not is_instance_valid(room):
		return
	# Esc fecha a inscrição; outras ações não abrem outro painel enquanto ela está ativa.
	if seal_panel.visible:
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			get_viewport().set_input_as_handled()
			_close_challenge()
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	# E0 e os quatro enigmas de orientação podem ser examinados.
	var door := _near_challenge()
	if door != null:
		get_viewport().set_input_as_handled()
		active_challenge = door
		seal_panel = $PainelSelo if door.blocked_id == FIRST_CHALLENGE else get_node(door.blocked_id)
		_lock_player()
		seal_panel.show_challenge()
		_refresh_attempts()
	elif _near_exit():
		seal_panel = $PainelSelo
		get_viewport().set_input_as_handled()
		_finish_run(true)

## Usa o marcador interno para examinar a porta sem encostar na colisão da grade.
func _near_challenge() -> Area2D:
	for door: Area2D in room.doors.values():
		if door.blocked_id in [FIRST_CHALLENGE, "D3", "D7", "D8", "D9"] and not door.opened and not door.opening:
			if player.global_position.distance_to(door.spawn_position()) <= INTERACTION_RANGE:
				return door
	return null

## Cancelar não altera a porta nem registra progresso.
func _close_challenge() -> void:
	if unlocking or finished: return
	active_challenge = null
	seal_panel.hide()
	player.controls_enabled = true

## Confirmação válida abre a grade e registra o resultado somente ao terminar.
func _confirm_challenge(sequence: Array[String]) -> void:
	if finished or get_tree().paused or unlocking or not seal_panel.visible or not is_instance_valid(active_challenge): return
	if active_challenge != _near_challenge(): return
	# E0 usa pedras; os demais validam a direção exportada no painel.
	var correct: bool = sequence == STONE_SOLUTION if active_challenge.blocked_id == FIRST_CHALLENGE else sequence.size() == 1 and sequence[0] == seal_panel.resposta
	if not correct:
		var id: String = active_challenge.blocked_id
		challenge_errors[id] = challenge_errors.get(id, 0) + 1
		if int(challenge_errors[id]) % 3 == 0:
			_close_challenge()
			_lose_life("Tentativas esgotadas: -1 vida. A porta permite tentar novamente.")
		else:
			seal_panel.show_incorrect()
			_refresh_attempts(true)
		return
	unlocking = true
	var door := active_challenge
	active_challenge = null
	seal_panel.hide()
	await door.open_passage()
	# Pontua somente uma vez por ID; reiniciar tentativas não apaga erros.
	if not solved_challenges.has(door.blocked_id):
		var errors: int = challenge_errors.get(door.blocked_id, 0)
		var earned := 300 if errors == 0 else (200 if errors == 1 else 100)
		score += earned
		notice = "Desafio concluído: +%s pontos." % earned
	solved_challenges[door.blocked_id] = true
	_refresh_score()
	unlocking = false
	player.controls_enabled = true

## A interação acompanha o marcador editável da saída oeste ou norte.
func _near_exit() -> bool:
	if not Map.EXITS.has(current_room):
		return false
	var marker := room.get_node_or_null("Saida/Interacao") as Marker2D
	return marker != null and player.global_position.distance_to(marker.global_position) <= INTERACTION_RANGE

## Comandos contextuais de inscrição e saída, sem dicas de navegação nesta etapa.
func _update_interaction_hint() -> void:
	interaction_label.text = ""
	if finished or transitioning or seal_panel.visible or unlocking:
		return
	if _near_exit():
		interaction_label.text = "E — Escapar"
	elif _near_challenge() != null:
		interaction_label.text = "E — Examinar inscrição"
	# A pista rimada permanece disponível; comandos próximos têm prioridade.
	elif Time.get_ticks_msec() < notice_until:
		interaction_label.text = notice
	elif is_instance_valid(room_effect):
		interaction_label.text = room_effect.dica

## Bloqueia movimento e pausa enquanto o painel está ativo.
func _lock_player() -> void:
	player.controls_enabled = false
	player.velocity = Vector2.ZERO

## Pausa sobre enigmas é permitida; travessias, queda e abertura continuam protegidas.
func blocks_pause_menu() -> bool:
	return transitioning or unlocking or falling or finished

func blocks_pause() -> bool:
	return finished or transitioning or unlocking or falling or (is_instance_valid(seal_panel) and seal_panel.visible)

## Recebe porta e corpo; rejeita destinos inválidos e concorrência antes de bloquear o movimento.
func request_transition(door: Area2D, body: CharacterBody2D) -> void:
	# Descarta sinais físicos pendentes de uma instância de sala já substituída.
	if not is_instance_valid(room) or room.doors.get(door.direction) != door: return
	# Ignora eventos físicos pendentes de uma posição anterior do personagem.
	if body.global_position.distance_to(door.spawn_position()) > 100.0: return
	# Uma interação modal impede travessias até o jogador recuperar o controle.
	if blocks_pause() or body != player or door == entry_lock or door.room_id != current_room or not door.opened: return
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
	# Restaura as conexões previstas no esboço e o progresso da partida atual.
	room.configure(id, rooms[id], solved_challenges)
	room.attach_player(player)
	current_room = id
	for door in room.doors.values(): door.requested.connect(request_transition)
	# Nascimento é um marcador salvo na cena. Travessias continuam usando a porta oposta.
	var spawn_marker := room.get_node_or_null("Nascimento") as Marker2D
	if not entry.is_empty():
		player.global_position = room.doors[entry].spawn_position()
	else:
		player.global_position = spawn_marker.global_position if spawn_marker != null else room.to_global(Map.CENTER_SPAWN)
	player.velocity = Vector2.ZERO
	entry_lock = null if entry.is_empty() else room.doors[entry]
	# Cada visita redefine a inversão, preservando a configuração da cena.
	room_effect = room.get_node_or_null("EfeitoSala")
	# Entrada fica protegida durante a recuperação, evitando retorno involuntário.
	return_position = player.global_position
	return_entry = entry_lock
	player.inverted_controls = is_instance_valid(room_effect) and room_effect.tipo == 1
	unlock_at = Time.get_ticks_msec()+250
	var bounds := Rect2(room.position+Map.CAMERA_BOUNDS.position,Map.CAMERA_BOUNDS.size)
	camera.limit_left = roundi(bounds.position.x)
	camera.limit_top = roundi(bounds.position.y)
	camera.limit_right = roundi(bounds.end.x)
	camera.limit_bottom = roundi(bounds.end.y)
	camera.reset_smoothing()
	camera.force_update_scroll()
	$HUD/Sala.text = "%s · %s" % [id, player.name]

## Mantém o placar nos nós editáveis do HUD.
func _refresh_score() -> void:
	$HUD/Status.update_status(lives, score)
	if not notice.is_empty():
		notice_until = Time.get_ticks_msec() + 6000

## O total de erros preserva o bônus; o módulo conta a rodada de três tentativas.
func _refresh_attempts(wrong := false) -> void:
	if not is_instance_valid(active_challenge): return
	var errors: int = challenge_errors.get(active_challenge.blocked_id, 0)
	var remaining := 3 - errors % 3
	var label: Label = seal_panel.feedback if seal_panel == $PainelSelo else seal_panel.get_node("Fundo/Painel/Feedback")
	label.text = ("Resposta incorreta. " if wrong else "") + "Tentativas: %s/3" % remaining
	if remaining == 1: label.text += " — Outro erro custará 1 vida."

## Perda de vida nunca sela o atalho permanentemente.
func _lose_life(reason: String) -> void:
	if finished: return
	lives = maxi(0, lives - 1)
	notice = reason
	_refresh_score()
	if lives == 0: _finish_run(false)

## Trava a partida e calcula o bônus de fuga uma única vez.
func _finish_run(won: bool) -> void:
	if finished: return
	finished = true
	escaped = won
	_lock_player()
	seal_panel.hide()
	active_challenge = null
	if won: score += 500 + lives * 100
	_refresh_score()
	var content = $Resultado/Overlay/Centro/Moldura/Conteudo
	content.get_node("Titulo").text = "Você escapou!" if won else "Fim da partida"
	content.get_node("Inscricao").text = ("Bônus de fuga: 500 + %s pelas vidas.\n" % (lives * 100) if won else "Suas vidas se esgotaram.\n") + "Pontuação final: %s   ·   Vidas: %s/3" % [score, lives]
	$Resultado.show()
	content.get_node("Acoes/Reiniciar").grab_focus()
