## PersonagemTopDown atende os CharacterBody2D de Aelin e Dorian. Depende do Input Map e AnimatedSprite2D; Labirinto bloqueia controls_enabled durante o fade.
extends CharacterBody2D
## Movimento XY compartilhado. A origem do corpo representa os pes do personagem.
@export_range(20.0, 400.0, 1.0) var speed: float = 144.0
@export var idle_prefix: String = "parada"
@export var controls_enabled: bool = true
## A sala ativa inverte os dois eixos; o labirinto restaura ao sair.
@export var inverted_controls: bool = false
## Preserva a profundidade do Inspector fora das sobreposições de portas.
var normal_z: int
var facing: String = "frente"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

## Inicializa movimento flutuante e animação parada ao entrar na árvore.
func _ready() -> void:
	normal_z = z_index
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_update_animation(Vector2.ZERO)

## Lê WASD normalizado, aplica velocidade e move com colisões. O bloqueio de controles produz vetor zero.
func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down") if controls_enabled else Vector2.ZERO
	# A animação acompanha o deslocamento real, inclusive na sala invertida.
	if inverted_controls: direction = -direction
	velocity = direction * speed
	move_and_slide()
	_update_animation(direction)
	_update_door_depth()

## Seleciona caminhada ou parada conforme direção e orientação anterior, sem reiniciar quadros desnecessariamente.
func _update_animation(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		# Em empate diagonal, manter a orientacao anterior se ela pertence ao par.
		# Isso evita alternancia entre horizontal e vertical a cada frame.
		if absf(direction.x) > absf(direction.y):
			facing = "direita" if direction.x > 0 else "esquerda"
		elif absf(direction.y) > absf(direction.x):
			facing = "frente" if direction.y > 0 else "costas"
		else:
			var horizontal := "direita" if direction.x > 0 else "esquerda"
			var vertical := "frente" if direction.y > 0 else "costas"
			if facing != horizontal and facing != vertical:
				facing = vertical
	var animation_name := StringName(("correndo" if not direction.is_zero_approx() else idle_prefix) + "_" + facing)
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
