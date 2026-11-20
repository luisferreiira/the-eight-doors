## PersonagemTopDown atende os CharacterBody2D de Aelin e Dorian. Depende do Input Map e AnimatedSprite2D; Labirinto bloqueia controls_enabled durante o fade.
extends CharacterBody2D
## Movimento XY compartilhado. A origem do corpo representa os pes do personagem.
@export_range(20.0, 400.0, 1.0) var speed: float = 144.0
@export var idle_prefix: String = "parada"
@export var controls_enabled: bool = true
## Cada cena do personagem recebe seu próprio efeito curto de passos pelo Inspector.
@export var footstep_stream: AudioStream
@export_range(8.0, 120.0, 1.0) var footstep_distance := 38.0
## A sala ativa inverte os dois eixos; o labirinto restaura ao sair.
@export var inverted_controls: bool = false
## Preserva a profundidade do Inspector fora das sobreposições de portas.
var normal_z: int
var facing: String = "frente"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _footstep_player: AudioStreamPlayer
var _footstep_distance_accumulated := 0.0

## Inicializa movimento flutuante e animação parada ao entrar na árvore.
func _ready() -> void:
	normal_z = z_index
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# O player local pode ser interrompido no mesmo passo que o deslocamento cessa.
	if footstep_stream != null:
		_footstep_player = AudioStreamPlayer.new()
		_footstep_player.name = "Passos"
		_footstep_player.stream = footstep_stream
		_footstep_player.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(_footstep_player)
		# Resolve o autoload ao entrar na árvore, inclusive nos testes com pré-carregamento.
		get_node("/root/EstadoJogo").register_sfx_player(_footstep_player)
	_update_animation(Vector2.ZERO)

## Lê WASD normalizado, aplica velocidade e move com colisões. O bloqueio de controles produz vetor zero.
func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down") if controls_enabled else Vector2.ZERO
	# A animação acompanha o deslocamento real, inclusive na sala invertida.
	if inverted_controls: direction = -direction
	velocity = direction * speed
	var previous_position := global_position
	move_and_slide()
	var actual_motion := global_position - previous_position
	_update_footsteps(actual_motion.length())
	# Usa o deslocamento resolvido pela física, não a tecla nem o vetor antes da inversão.
	_update_animation(actual_motion)
	_update_door_depth()

## Conta somente distância física percorrida; colisão, bloqueio ou pausa interrompem o áudio.
func _update_footsteps(distance_moved: float) -> void:
	if _footstep_player == null:
		return
	if not controls_enabled or get_tree().paused or distance_moved <= 0.01:
		_footstep_distance_accumulated = 0.0
		_footstep_player.stop()
		return
	_footstep_distance_accumulated += distance_moved
	if _footstep_distance_accumulated >= footstep_distance:
		_footstep_distance_accumulated = fmod(_footstep_distance_accumulated, footstep_distance)
		if not _footstep_player.playing:
			_footstep_player.play()

## Corta o passo imediatamente quando o overlay pausa a árvore do jogo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and is_instance_valid(_footstep_player):
		_footstep_distance_accumulated = 0.0
		_footstep_player.stop()


## Seleciona corrida horizontal, direcao vertical ou parada; animacoes especiais mantem prioridade.
func _update_animation(direction: Vector2) -> void:
	var locomotion := [&"run_right", &"run_left", &"correndo_costas", &"correndo_frente", &"correndo_direita", &"correndo_esquerda", &"parada_costas", &"parada_frente", &"parada_direita", &"parada_esquerda", &"parado_costas", &"parado_frente", &"parado_direita", &"parado_esquerda"]
	if not locomotion.has(sprite.animation) and sprite.is_playing():
		return
	var moving := direction.length_squared() > 0.0001
	# Pequenas diferenças de precisão na diagonal preservam o rumo anterior.
	if moving:
		if absf(direction.x) > absf(direction.y) * 1.05:
			facing = "direita" if direction.x > 0 else "esquerda"
		elif absf(direction.y) > absf(direction.x) * 1.05:
			facing = "frente" if direction.y > 0 else "costas"
		else:
			var horizontal := "direita" if direction.x > 0 else "esquerda"
			var vertical := "frente" if direction.y > 0 else "costas"
			if facing != horizontal and facing != vertical:
				facing = vertical
	var animation_name: StringName
	if moving and facing in ["direita", "esquerda"]:
		animation_name = &"run_right" if facing == "direita" else &"run_left"
	else:
		var prefix := "correndo" if moving else idle_prefix
		animation_name = StringName(prefix + "_" + facing)
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)

## Eleva o ator nas portas do fundo; as portas inferiores continuam em primeiro plano.
## A moldura e a grade continuam acima dos tiles originais, sem alterar a colisão.
func _update_door_depth() -> void:
	z_index = normal_z
	var passages := get_parent().get_node_or_null("Passagens")
	if passages == null: return
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null: return
	var size := texture.get_size() * sprite.scale.abs()
	var actor_rect := Rect2(sprite.global_position - size * 0.5, size)
	for door in passages.get_children():
		# Passagens de cenas antigas não têm direção nem a sobreposição do labirinto.
		var door_direction: Variant = door.get("direction")
		if not door_direction is String or door_direction.is_empty(): continue
		# Sul e diagonais inferiores ocultam o ator, como as paredes da frente.
		if door_direction in ["S", "SE", "SO"]: continue
		# Nas laterais, a posição dos pés define de que lado da profundidade está o ator.
		if door_direction in ["L", "O"] and global_position.y < door.global_position.y: continue
		var visual := door.get_node_or_null("VisualEspecial")
		if visual == null: continue
		for part in visual.get_children():
			if not part is Sprite2D or not part.is_visible_in_tree(): continue
			var rect: Rect2 = part.get_rect()
			var bounds := Rect2(part.to_global(rect.position), Vector2.ZERO)
			for corner in [rect.end, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y)]:
				bounds = bounds.expand(part.to_global(corner))
			if bounds.intersects(actor_rect):
				z_index = maxi(z_index, visual.z_index + part.z_index + 1)
