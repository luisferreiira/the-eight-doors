## CameraExploracao atende a Camera2D filha do personagem. Labirinto atualiza seus limites globais a cada sala; posição local evita somar o deslocamento duas vezes.
extends Camera2D
## Camera local da cena jogavel. O script de enquadramento da referencia e preservado.
## O pai e Aelin: nao somar novamente a posicao global do personagem.

## Configura zoom, acompanhamento físico e limites iniciais. Ativa a câmera sem suavização para preservar a apresentação existente.
func _ready() -> void:
	position = Vector2(0, -24)
	offset = Vector2.ZERO
	zoom = Vector2.ONE
	position_smoothing_enabled = false
	rotation_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	limit_left = 32
	limit_top = 16
	limit_right = 1088
	limit_bottom = 992
	limit_smoothed = false
	make_current()
	reset_smoothing()
	force_update_scroll()
