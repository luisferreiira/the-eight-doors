extends CanvasLayer
signal confirmed(sequence: Array[String])
signal dismissed
@export var resposta := "oeste"
@onready var field: LineEdit = $Fundo/Painel/Resposta
## Conecta os controles persistidos; desenho e textos ficam na cena.
func _ready():
 $Fundo/Painel/Confirmar.pressed.connect(_confirm)
 $Fundo/Painel/Fechar.pressed.connect(func(): dismissed.emit())
 field.text_submitted.connect(func(_text): _confirm())
 hide()
func show_challenge():
 field.clear()
 # Limpa somente as anotações da tentativa anterior, sem alterar o mapa.
 for node in $Fundo/Painel.get_children():
  if node is Button and node.toggle_mode: node.button_pressed = false
 $Fundo/Painel/Feedback.text = "Escreva uma direção."
 show()
 field.call_deferred("grab_focus")
func show_incorrect():
 $Fundo/Painel/Feedback.text = "Esse rumo não despertou a pedra."
 field.grab_focus()
## Normaliza abreviações e separadores antes de enviar a tentativa.
func _confirm():
 var value = field.text.strip_edges().to_lower().replace("-", "").replace(" ", "")
 value = {"o":"oeste","w":"oeste","l":"leste","e":"leste","so":"sudoeste","sw":"sudoeste","no":"noroeste","nw":"noroeste"}.get(value,value)
 if value.is_empty(): return
 var result: Array[String] = [value]
 # Limpa após capturar a resposta: erros deixam o campo pronto sem apagar o feedback.
 field.clear()
 confirmed.emit(result)
