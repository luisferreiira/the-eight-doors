extends CanvasLayer

signal confirmed(sequence: Array[String])
signal dismissed

@export var challenge_title: String = "O ciclo da luz"
@export_multiline var inscription: String = "Primeiro, pequenas luzes fazem o céu brilhar. Depois, a guardiã da noite vem reinar. Por último, nasce o dia para a sombra dissipar."
@export var choice_names: PackedStringArray = PackedStringArray(["Sol", "Estrela", "Lua"])
@export var solution: PackedStringArray = PackedStringArray(["Estrela", "Lua", "Sol"])
@export var choice_icons: Array[Texture2D] = []
@export var initial_message: String = "Escolha as pedras na ordem da inscrição."
@export var incorrect_message: String = "A ordem não despertou a pedra. Tente novamente."
@export_range(360.0, 580.0, 10.0) var panel_width: float = 390.0

var overlay: ColorRect
var title: Label
var clue: Label
var selection: Label
var feedback: Label
var confirm_button: Button
var choices: HBoxContainer
var actions: HBoxContainer
var sequence: Array[String] = []

# Conecta os nós visuais persistidos e configura as opções declaradas por cada cena de desafio.
func _ready() -> void:
	overlay = $Overlay
	var content := $Overlay/Centro/Moldura/Conteudo
	title = content.get_node("Titulo")
	clue = content.get_node("Inscricao")
	selection = content.get_node("Sequencia")
	feedback = content.get_node("Feedback")
	choices = content.get_node("Pedras")
	actions = content.get_node("Acoes")
	confirm_button = actions.get_node("Confirmar")
	title.text = challenge_title
	clue.text = inscription
	feedback.text = initial_message
	content.custom_minimum_size.x = panel_width
	for index in range(choices.get_child_count()):
		var button := choices.get_child(index) as Button
		button.visible = index < choice_names.size()
		if not button.visible:
			continue
		button.text = choice_names[index]
		button.icon = choice_icons[index] if index < choice_icons.size() else null
		button.pressed.connect(_select_choice.bind(choice_names[index]))
	actions.get_node("Limpar").pressed.connect(_clear_selection)
	confirm_button.pressed.connect(_confirm)
	actions.get_node("Fechar").pressed.connect(func(): dismissed.emit())
	_clear_selection()
	hide()

# Reabre o painel e limpa apenas a seleção atual da tentativa.
func show_challenge() -> void:
	overlay.show()
	feedback.text = initial_message
	_clear_selection()
	show()
	for button in choices.get_children():
		if button.visible:
			button.grab_focus()
			break

# Expõe a sequência configurada para o controlador sem duplicar respostas nos scripts.
func get_solution() -> Array[String]:
	var result: Array[String] = []
	for choice in solution:
		result.append(choice)
	return result

# Permite que o controlador atualize tentativas no feedback da cena editável.
func get_feedback_label() -> Label:
	return feedback

# Mostra erro e prepara outra tentativa sem fechar o desafio.
func show_incorrect() -> void:
	feedback.text = incorrect_message
	_clear_selection()

# Adiciona uma opção única até completar o número de itens da solução.
func _select_choice(choice: String) -> void:
	if sequence.size() < solution.size() and not sequence.has(choice):
		sequence.append(choice)
		_update_selection()

# Limpa a sequência atual e atualiza o estado do botão Confirmar.
func _clear_selection() -> void:
	sequence.clear()
	_update_selection()

# Exibe a ordem escolhida e habilita confirmação quando todos os itens foram selecionados.
func _update_selection() -> void:
	var slots := PackedStringArray(sequence)
	while slots.size() < solution.size():
		slots.append("___")
	selection.text = "   →   ".join(slots)
	confirm_button.disabled = sequence.size() != solution.size()

# Envia a ordem selecionada ao controlador do labirinto.
func _confirm() -> void:
	if not confirm_button.disabled:
		confirmed.emit(sequence.duplicate())
