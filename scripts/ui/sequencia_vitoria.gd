extends CanvasLayer

signal completed

@export_range(0.5, 6.0, 0.1) var dissolve_duration := 2.8
@export_range(0.0, 2.0, 0.05) var white_hold_duration := 0.45

@onready var white_veil: ColorRect = $VeloBranco
var playing := false

# Dissolve o mundo depois que o personagem já atravessou a saída.
func play() -> void:
	if playing:
		return
	playing = true
	show()
	white_veil.modulate.a = 1.0
	white_veil.material.set_shader_parameter("progress", 0.0)
	var dissolve_tween := create_tween()
	dissolve_tween.tween_method(_set_dissolve_progress, 0.0, 1.0, dissolve_duration)
	await dissolve_tween.finished
	await get_tree().create_timer(white_hold_duration).timeout
	playing = false
	completed.emit()

# Atualiza o avanço do shader persistido na cena da sequência.
func _set_dissolve_progress(value: float) -> void:
	white_veil.material.set_shader_parameter("progress", value)
