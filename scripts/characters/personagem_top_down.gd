## PersonagemTopDown atende os CharacterBody2D de Aelin e Dorian. Depende do Input Map e AnimatedSprite2D; Labirinto bloqueia controls_enabled durante o fade.
extends CharacterBody2D
## Movimento XY compartilhado. A origem do corpo representa os pes do personagem.
@export_range(20.0, 400.0, 1.0) var speed: float = 144.0
@export var idle_prefix: String = "parada"
@export var controls_enabled: bool = true
## A sala ativa inverte os dois eixos; o labirinto restaura ao sair.
@export var inverted_controls: bool = false
var facing: String = "frente"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

## Inicializa movimento flutuante e animação parada ao entrar na árvore.
func _ready() -> void:
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
