extends CanvasLayer

signal completed

@export_range(0.5, 6.0, 0.1) var dissolve_duration := 2.8
@export_range(0.0, 2.0, 0.05) var white_hold_duration := 0.45

@onready var white_veil: ColorRect = $VeloBranco
var playing := false

# Dissolve o mundo depois que o personagem já atravessou a saída.
func play(sala: Node2D, arco: Node2D) -> void:
	if playing:
		return
	playing = true
	show()
	white_veil.modulate.a = 1.0
	white_veil.material.set_shader_parameter("progress", 0.0)
	# Agrupa as células por distância ao arco para consumir primeiro os tiles mais distantes.
	var origem := arco.global_position if arco != null else sala.global_position
	var faixas: Array[Array] = []
	var largura := 24.0
	for camada: TileMapLayer in sala.find_children("*", "TileMapLayer", true, false):
		for celula in camada.get_used_cells():
			var centro := camada.to_global(camada.map_to_local(celula))
			var indice := floori(centro.distance_to(origem) / largura)
			while faixas.size() <= indice:
				faixas.append([])
			faixas[indice].append([camada, celula])
	var total := faixas.size()
	var dissolve_tween := create_tween()
	# O eco começa quando a última faixa se desfaz e a decoração já se apagou.
	dissolve_tween.tween_method(func(fracao: float):
		while faixas.size() > roundi(total * (1.0 - fracao)):
			for tile in faixas.pop_back():
				tile[0].erase_cell(tile[1])
	, 0.0, 1.0, dissolve_duration * 0.60)
	dissolve_tween.parallel().tween_property(sala, "modulate:a", 0.0, dissolve_duration * 0.30).set_delay(dissolve_duration * 0.30)
	dissolve_tween.tween_callback(func():
		var tela := white_veil.get_viewport_transform() * Vector2.ZERO
		if arco != null:
			tela = arco.get_global_transform_with_canvas().origin
		white_veil.material.set_shader_parameter("origem", white_veil.get_global_transform_with_canvas().affine_inverse() * tela / white_veil.size)
	)
	dissolve_tween.tween_method(_set_dissolve_progress, 0.0, 1.0, dissolve_duration * 0.40)
	await dissolve_tween.finished
	await get_tree().create_timer(white_hold_duration).timeout
	playing = false
	completed.emit()

# Atualiza o avanço do shader persistido na cena da sequência.
func _set_dissolve_progress(value: float) -> void:
	white_veil.material.set_shader_parameter("progress", value)
