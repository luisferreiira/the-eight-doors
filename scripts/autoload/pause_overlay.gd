extends CanvasLayer

const MENU_SCENES := [
	"res://scenes/ui/menus/MenuInicial.tscn",
	"res://scenes/ui/menus/EscolhaPersonagem.tscn"
]
const PAUSE_ICON := "res://assets/ui/pausar.png"
const RESUME_ICON := "res://assets/ui/voltar.png"
const RESTART_ICON := "res://assets/ui/reiniciar.png"

var _ui: Control
var _pause_button: TextureButton
var _shade: ColorRect
var _pause_panel: PanelContainer
var _resume_button: TextureButton
var _changing_scene := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_build_ui()
	get_tree().scene_changed.connect(_refresh_for_scene)
	call_deferred("_refresh_for_scene")

func _build_ui() -> void:
	_ui = Control.new()
	_ui.name = "PauseControls"
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	_ui.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_ui)

	_pause_button = _make_button(PAUSE_ICON, Vector2(74.0, 45.0), "Pausar")
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.anchor_top = 0.0
	_pause_button.anchor_bottom = 0.0
	_pause_button.offset_left = -82.0
	_pause_button.offset_top = 8.0
	_pause_button.offset_right = -8.0
	_pause_button.offset_bottom = 53.0
	_ui.add_child(_pause_button)
	_pause_button.button_down.connect(EstadoJogo.play_button_sound)
	_pause_button.pressed.connect(_pause_game)

	_shade = ColorRect.new()
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.0, 0.0, 0.0, 0.58)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.visible = false
	_ui.add_child(_shade)

	_pause_panel = PanelContainer.new()
	_pause_panel.name = "PauseMenu"
	_pause_panel.anchor_left = 0.5
	_pause_panel.anchor_right = 0.5
	_pause_panel.anchor_top = 0.5
	_pause_panel.anchor_bottom = 0.5
	_pause_panel.offset_left = -130.0
	_pause_panel.offset_top = -88.0
	_pause_panel.offset_right = 130.0
	_pause_panel.offset_bottom = 88.0
	_pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.043, 0.035, 0.96)
	panel_style.border_color = Color(0.72, 0.43, 0.18, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_top = 18.0
	panel_style.content_margin_bottom = 18.0
	_pause_panel.add_theme_stylebox_override("panel", panel_style)
	_ui.add_child(_pause_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_pause_panel.add_child(content)
	var title := Label.new()
	title.text = "Jogo pausado"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	content.add_child(buttons)

	var resume_button := _make_button(RESUME_ICON, Vector2(74.0, 45.0), "Voltar ao jogo")
	resume_button.button_down.connect(EstadoJogo.play_button_sound)
	resume_button.pressed.connect(_resume_game)
	buttons.add_child(resume_button)
	_resume_button = resume_button

	var restart_button := _make_button(RESTART_ICON, Vector2(74.0, 45.0), "Reiniciar partida com o mesmo personagem")
	restart_button.button_down.connect(EstadoJogo.play_button_sound)
	restart_button.pressed.connect(_restart_current_scene)
	buttons.add_child(restart_button)

	var menu_button := Button.new()
	menu_button.text = "Voltar ao menu inicial"
	menu_button.button_down.connect(EstadoJogo.play_button_sound)
	menu_button.pressed.connect(_return_to_menu)
	content.add_child(menu_button)
	EstadoJogo.register_volume_control(EstadoJogo.add_volume_control(_shade, 0.5))

func _make_button(texture_path: String, button_size: Vector2, description: String) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = button_size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	var icon := load(texture_path) as Texture2D
	button.texture_normal = icon
	button.texture_hover = icon
	button.texture_pressed = icon
	button.tooltip_text = description
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button

## A pausa pertence apenas ao labirinto, nunca às telas ou prévias do editor.
func _is_gameplay() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.is_in_group("gameplay")

func _refresh_for_scene(_scene_root: Node = null) -> void:
	_changing_scene = false
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
	# Não congelar o fade pela metade nem trocar de cena durante uma travessia.
	if get_tree().current_scene.transitioning:
		return
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

func _restart_current_scene() -> void:
	if not _is_gameplay() or _changing_scene: return
	_changing_scene = true
	call_deferred("_change_scene", true)

func _return_to_menu() -> void:
	if not _is_gameplay() or _changing_scene: return
	_changing_scene = true
	call_deferred("_change_scene", false)

func _change_scene(restart: bool) -> void:
	get_tree().paused = false
	_ui.hide()
	var error := get_tree().reload_current_scene() if restart else get_tree().change_scene_to_file(EstadoJogo.MENU)
	if error != OK:
		push_error("Não foi possível trocar de cena: %s" % error)
		_refresh_for_scene()

func _input(event: InputEvent) -> void:
	if not _is_gameplay() or _changing_scene: return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()
