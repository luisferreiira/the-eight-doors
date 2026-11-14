extends CanvasLayer

## Interfaces persistidas e editáveis no 2D; o autoload cuida somente do comportamento.
const PauseScene = preload("res://scenes/ui/gameplay/pausa.tscn")
const FadeScene = preload("res://scenes/ui/gameplay/fade_reinicio.tscn")
var _fade_screen: ColorRect
var _fade_animation: AnimationPlayer

var _ui: Control
var _pause_button: TextureButton
var _shade: ColorRect
var _pause_panel: PanelContainer
var _resume_button: TextureButton
var _changing_scene := false
## Recupera o campo de resposta após continuar, sem apagar a tentativa.
var _previous_focus: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_build_ui()
	get_tree().scene_changed.connect(_refresh_for_scene)
	call_deferred("_refresh_for_scene")

## Instancia os nós salvos nas cenas e conecta ações sem reconstruir o layout.
func _build_ui() -> void:
	_ui = PauseScene.instantiate()
	add_child(_ui)
	_pause_button = _ui.get_node("Pausar")
	_shade = _ui.get_node("Sombra")
	_pause_panel = _ui.get_node("PauseMenu")
	_resume_button = _pause_panel.get_node("Conteudo/Botoes/Continuar/Botao")
	var restart_button: TextureButton = _pause_panel.get_node("Conteudo/Botoes/Reiniciar/Botao")
	var menu_button: Button = _pause_panel.get_node("Conteudo/Menu")
	for button: BaseButton in [_pause_button, _resume_button, restart_button, menu_button]:
		button.button_down.connect(EstadoJogo.play_button_sound)
	_pause_button.pressed.connect(_pause_game)
	_resume_button.pressed.connect(_resume_game)
	restart_button.pressed.connect(_restart_current_scene)
	menu_button.pressed.connect(_return_to_menu)
	EstadoJogo.bind_volume_control(_shade.get_node("VolumeControl"))
	var fade: CanvasLayer = FadeScene.instantiate()
	add_child(fade)
	_fade_screen = fade.get_node("Tela")
	_fade_animation = fade.get_node("AnimationPlayer")

## A pausa pertence apenas ao labirinto, nunca às telas ou prévias do editor.
func _is_gameplay() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.is_in_group("gameplay")

## A chegada da cena nova não pode liberar a interface no meio do fade.
func _refresh_for_scene(_scene_root: Node = null) -> void:
	if _changing_scene: return
	var gameplay := _is_gameplay()
	if not gameplay:
		get_tree().paused = false
	_ui.visible = gameplay
	_pause_button.visible = gameplay and not get_tree().paused
	_shade.visible = gameplay and get_tree().paused
	_pause_panel.visible = gameplay and get_tree().paused

func _pause_game() -> void:
	if not _is_gameplay() or _changing_scene or get_tree().paused:
		return
	# Enigmas aceitam pausa; apenas operações transitórias e vitória a bloqueiam.
	if get_tree().current_scene.blocks_pause_menu():
		return
	_previous_focus = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	_pause_button.visible = false
	_shade.visible = true
	_pause_panel.visible = true
	_resume_button.grab_focus()

func _resume_game() -> void:
	if _changing_scene: return
	get_tree().paused = false
	_refresh_for_scene()
	_resume_button.release_focus()
	if is_instance_valid(_previous_focus): _previous_focus.grab_focus()

func _restart_current_scene() -> void:
	if not _is_gameplay() or _changing_scene: return
	_changing_scene = true
	call_deferred("_change_scene", true)

func _return_to_menu() -> void:
	if not _is_gameplay() or _changing_scene: return
	_changing_scene = true
	call_deferred("_change_scene", false)

## Mantém o mundo parado durante todo o fade e recarrega somente sob preto completo.
func _change_scene(restart: bool) -> void:
	var was_paused := get_tree().paused
	get_tree().paused = true
	_resume_button.release_focus()
	_fade_screen.color.a = 0.0
	_fade_screen.show()
	_fade_animation.play("escurecer")
	await _fade_animation.animation_finished
	_ui.hide()
	var error := get_tree().reload_current_scene() if restart else get_tree().change_scene_to_file(EstadoJogo.MENU)
	if error == OK:
		await get_tree().scene_changed
	else:
		push_error("Não foi possível trocar de cena: %s" % error)
	# A cena nova já está pronta; mantém um instante preto antes de revelá-la.
	_fade_animation.play("revelar")
	await _fade_animation.animation_finished
	_fade_screen.hide()
	get_tree().paused = was_paused if error != OK else false
	_changing_scene = false
	_refresh_for_scene()

## Bloqueia comandos repetidos durante o reinício, inclusive na cena recém-carregada.
func _input(event: InputEvent) -> void:
	if _changing_scene:
		get_viewport().set_input_as_handled()
		return
	if not _is_gameplay(): return
	# Esc abre a pausa também sobre a inscrição; Fechar cancela o enigma.
	if not get_tree().paused and get_tree().current_scene.blocks_pause_menu(): return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()
