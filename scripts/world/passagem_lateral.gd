extends Area2D
## Passagem aberta; o sinal permite conectar futuramente uma transicao de sala.
signal passagem_solicitada(personagem: Node2D, destino: String)
@export var destino: String = ""
@export var aberta: bool = true
@export_enum("Leste", "Oeste") var lado: String = "Leste"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	set_aberta(aberta)

func set_aberta(value: bool) -> void:
	aberta = value
	if has_node("Bloqueio/CollisionShape2D"):
		$Bloqueio/CollisionShape2D.set_deferred("disabled", aberta)

func _on_body_entered(body: Node2D) -> void:
	if aberta and body is CharacterBody2D:
		passagem_solicitada.emit(body, destino)
