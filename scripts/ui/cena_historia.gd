extends Control

signal concluida

@export var abrir_gameplay := false
@export var duracao_fade := 0.4
@export var texto_final := "Continuar"

@onready var quadros: Control = get_node_or_null("Quadros")
@onready var voltar: Button = $Acoes/Voltar
@onready var avancar: Button = $Acoes/Avancar
@onready var pular: Button = $Acoes/Pular
@onready var cortina: ColorRect = $Cortina

var indice := 0
var ativa := false
var trocando := false
var revelacao: Tween

## Liga os controles persistidos. A abertura roda como cena principal e os finais são sobreposições.
func _ready() -> void:
	# Liga o novo botão à mesma navegação dos outros quadros.
	voltar.pressed.connect(_voltar)
	avancar.pressed.connect(_avancar)
	pular.pressed.connect(_concluir)
	# Ilumina a arte do botão para preservar o feedback visual sem borda externa.
	for botao: Button in [voltar, avancar, pular]:
		var atualizar := _atualizar_realce.bind(botao)
		botao.mouse_entered.connect(atualizar)
		botao.mouse_exited.connect(atualizar)
		botao.focus_entered.connect(atualizar)
		botao.focus_exited.connect(atualizar)
	# Os ícones preservam o som de confirmação e o controle de volume usados nos menus.
	var state := get_node_or_null("/root/EstadoJogo")
	if state != null:
		voltar.button_down.connect(state.play_button_sound)
		avancar.button_down.connect(state.play_button_sound)
		pular.button_down.connect(state.play_button_sound)
	if abrir_gameplay:
		state.configurar_tela(false)
		iniciar()

## Destaca o botão sob o cursor ou com foco de teclado.
func _atualizar_realce(botao: Button) -> void:
	botao.modulate = Color(1.18, 1.13, 1.04) if botao.is_hovered() or botao.has_focus() else Color.WHITE

## Recomeça do primeiro quadro e revela a cena a partir do escuro.
func iniciar() -> void:
	ativa = true
	_mostrar_quadro(0)
	cortina.color.a = 1.0
	show()
	avancar.grab_focus()
	revelacao = create_tween()
	revelacao.tween_property(cortina, "color:a", 0.0, duracao_fade)

## Usa o conteúdo e o layout de cada quadro editável na cena.
func _mostrar_quadro(proximo: int) -> void:
	# Interrompe o quadro anterior para reiniciar a animação se ele for visitado de novo.
	var anterior := quadros.get_child(indice).get_node_or_null("Animacao") as AnimationPlayer
	if anterior != null:
		anterior.stop()
	indice = proximo
	for quadro: Control in quadros.get_children():
		quadro.visible = quadro.get_index() == indice
	# Alterna os textos do quadro usando a escolha que o menu já guarda.
	var atual := quadros.get_child(indice)
	var texto_aelin := atual.get_node_or_null("Conteudo/TextoAelin") as Label
	var texto_dorian := atual.get_node_or_null("Conteudo/TextoDorian") as Label
	if texto_aelin != null and texto_dorian != null:
		var estado := get_node("/root/EstadoJogo")
		var escolheu_dorian: bool = estado.personagem_selecionado == "personagem_2"
		texto_aelin.visible = not escolheu_dorian
		texto_dorian.visible = escolheu_dorian
	# Quadros com movimento próprio apontam para uma animação persistida na cena.
	var animacao := atual.get_node_or_null("Animacao") as AnimationPlayer
	if animacao != null:
		animacao.play("revelar")
		animacao.advance(0)
	# Mantém o ícone e informa o destino do último quadro ao passar o mouse ou usar leitor de tela.
	var acao := texto_final if indice == quadros.get_child_count() - 1 else "Continuar"
	avancar.tooltip_text = acao
	avancar.accessibility_name = acao
	# Ao voltar ao primeiro quadro, transfere o foco antes de esconder o botão.
	if indice == 0 and voltar.has_focus():
		avancar.grab_focus()
	voltar.visible = indice > 0
	pular.focus_next = pular.get_path_to(voltar if voltar.visible else avancar)

## Avança para o próximo quadro ou conclui a história.
func _avancar() -> void:
	if not ativa or trocando:
		return
	if indice == quadros.get_child_count() - 1:
		_concluir()
		return
	_trocar_quadro(indice + 1)

## Permite reler o quadro anterior sem sair da história.
func _voltar() -> void:
	if not ativa or trocando or indice == 0:
		return
	_trocar_quadro(indice - 1)

## Usa o mesmo fade nos dois sentidos da navegação.
func _trocar_quadro(proximo: int) -> void:
	trocando = true
	if revelacao.is_running():
		revelacao.kill()
	var transicao := create_tween()
	transicao.tween_property(cortina, "color:a", 1.0, duracao_fade * 0.5)
	transicao.tween_callback(_mostrar_quadro.bind(proximo))
	transicao.tween_property(cortina, "color:a", 0.0, duracao_fade)
	await transicao.finished
	trocando = false

## Mantém o destino do gameplay configurado e devolve os desfechos ao resultado da partida.
func _concluir() -> void:
	if not ativa or trocando:
		return
	if abrir_gameplay:
		# Fecha a abertura em preto antes de carregar a caverna e ignora cliques duplicados.
		trocando = true
		if revelacao.is_running():
			revelacao.kill()
		var saida := create_tween()
		saida.tween_property(cortina, "color:a", 1.0, duracao_fade)
		await saida.finished
		var state := get_node("/root/EstadoJogo")
		var erro := get_tree().change_scene_to_file(state.cena_gameplay)
		if erro != OK:
			trocando = false
			cortina.color.a = 0.0
			push_error("Não foi possível abrir o labirinto: %s" % erro)
			return
	ativa = false
	hide()
	concluida.emit()
