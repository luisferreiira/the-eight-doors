extends CanvasLayer

## Painel reutilizável: o labirinto recebe a confirmação e aplica o resultado.
signal confirmed(sequence: Array[String])
signal dismissed

var overlay: ColorRect
var title: Label
var clue: Label
var selection: Label
var feedback: Label
var confirm_button: Button
var choices: HBoxContainer
var actions: HBoxContainer
var sequence: Array[String] = []
var initial_feedback := ""

## Os nós visuais estão na cena; o script conecta apenas o comportamento.
func _ready() -> void:
	overlay = $Overlay
	var content := $Overlay/Centro/Moldura/Conteudo
	title = content.get_node("Titulo")
	clue = content.get_node("Inscricao")
	selection = content.get_node("Sequencia")
	feedback = content.get_node("Feedback")
	initial_feedback = feedback.text
	choices = content.get_node("Pedras")
	actions = content.get_node("Acoes")
	confirm_button = actions.get_node("Confirmar")
	for button in choices.get_children():
		button.pressed.connect(_select_stone.bind(button.name))
	actions.get_node("Limpar").pressed.connect(_clear_selection)
	confirm_button.pressed.connect(_confirm)
	actions.get_node("Fechar").pressed.connect(func(): dismissed.emit())
	hide()

## Reabre os nós existentes preservando o layout e os textos editados na cena.
func show_challenge() -> void:
	# Restaura a inscrição ao reabrir, inclusive após cancelamento.
	overlay.show()
	feedback.text = initial_feedback
	_clear_selection()
	show()
	choices.get_child(0).grab_focus()

## A vitória possui sua própria cena editável e mantém o bloqueio modal.
func show_victory(restart: Callable, menu: Callable) -> void:
	var victory = preload("res://scenes/ui/gameplay/vitoria.tscn").instantiate()
	get_parent().add_child(victory)
	victory.get_node("Overlay/Centro/Moldura/Conteudo/Acoes/Reiniciar").pressed.connect(restart)
	victory.get_node("Overlay/Centro/Moldura/Conteudo/Acoes/Menu").pressed.connect(menu)
	show()
	overlay.hide()
	victory.get_node("Overlay/Centro/Moldura/Conteudo/Acoes/Reiniciar").grab_focus()

## A tentativa incorreta limpa a ordem para uma nova tentativa.
func show_incorrect() -> void:
	# Erros permitem tentar novamente; penalidades serão tratadas em outra etapa.
	feedback.text = "A ordem não despertou a pedra. Tente novamente."
	_clear_selection()

func _select_stone(stone: String) -> void:
	if sequence.size() < choices.get_child_count() and not sequence.has(stone):
		sequence.append(stone)
		_update_selection()

func _clear_selection() -> void:
	sequence.clear()
	_update_selection()

func _update_selection() -> void:
	var slots := PackedStringArray(sequence)
	while slots.size() < choices.get_child_count():
		slots.append("___")
	selection.text = "   →   ".join(slots)
	confirm_button.disabled = sequence.size() != choices.get_child_count()

func _confirm() -> void:
	if not confirm_button.disabled:
		confirmed.emit(sequence.duplicate())
