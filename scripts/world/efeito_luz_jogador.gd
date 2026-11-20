extends Node2D

@onready var luz: PointLight2D = $Luz
var personagem: CharacterBody2D

# Encontra o personagem anexado à sala para manter a luz independente da personagem escolhida.
func _process(_delta: float) -> void:
	if not is_instance_valid(personagem):
		for filho in get_parent().get_children():
			if filho is CharacterBody2D:
				personagem = filho
				break
	if is_instance_valid(personagem):
		luz.global_position = personagem.global_position + Vector2(0, -24)
