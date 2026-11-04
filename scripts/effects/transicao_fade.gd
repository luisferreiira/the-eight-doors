extends CanvasLayer
## TransicaoFade: sobreposição persistente criada por Labirinto.
## Usa Tween e ColorRect nativos; não depende da câmera nem da sala removida.
var panel: ColorRect

## Prepara uma cobertura preta acima da vinheta e do HUD, inicialmente transparente.
func _ready() -> void:
	layer = 100
	panel = ColorRect.new()
	panel.color = Color(0,0,0,0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## Anima a opacidade por 0,8 s; Labirinto aguarda o término antes de carregar.
func escurecer() -> void:
	var tween := create_tween()
	tween.tween_property(panel,"color:a",1.0,0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished

## Mantém preto por 0,4 s e revela por 0,8 s, completando os dois segundos.
func revelar() -> void:
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(panel,"color:a",0.0,0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished
