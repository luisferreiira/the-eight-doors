extends Camera2D
## Apenas enquadramento; nunca altera a geometria ou os objetos da sala.
@export var enquadramento_automatico: bool = true
@export var area_da_sala := Rect2(-80, -32, 1280, 1088)
@export_range(0.5, 1.0, 0.01) var margem_enquadramento: float = 0.96

func _ready() -> void:
	if enquadramento_automatico:
		get_viewport().size_changed.connect(_enquadrar)
		_enquadrar()

func _enquadrar() -> void:
	if not enquadramento_automatico:
		return
	var tamanho := get_viewport_rect().size
	var fator := minf(tamanho.x / area_da_sala.size.x, tamanho.y / area_da_sala.size.y) * margem_enquadramento
	zoom = Vector2.ONE * fator
	position = area_da_sala.get_center()
