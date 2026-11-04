extends Control

const SCENA_ESCOLHA := "res://scenes/ui/menus/EscolhaPersonagem.tscn"
@onready var fundo: TextureRect = $Fundo
@onready var brasas: CPUParticles2D = $EfeitosAmbiente/Brasas
@onready var play: TextureButton = $Interface/Botoes/Play
@onready var quit: TextureButton = $Interface/Botoes/Quit
@onready var transicao: ColorRect = $Transicao
var button_tweens: Dictionary = {}
var transitioning := false
var intro: Tween

func _ready() -> void:
	EstadoJogo.configurar_tela(true)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	EstadoJogo.ensure_menu_music()
	EstadoJogo.register_volume_control(EstadoJogo.add_volume_control(self))
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	brasas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	brasas.color_ramp = _ember_gradient()
	play.pressed.connect(_on_play)
	quit.pressed.connect(_on_quit)
	_connect_button_effects(play)
	_connect_button_effects(quit)
	transicao.visible = true
	transicao.modulate.a = 1.0
	transicao.mouse_filter = Control.MOUSE_FILTER_STOP
	play.disabled = true
	quit.disabled = true
	await get_tree().process_frame
	fundo.pivot_offset = fundo.size * 0.5
	fundo.resized.connect(_update_background_pivot)
	intro = create_tween()
	intro.tween_property(transicao, "modulate:a", 0.0, 1.0)
	intro.finished.connect(func():
		transicao.mouse_filter = Control.MOUSE_FILTER_IGNORE
		play.disabled = false
		quit.disabled = false
		play.grab_focus())
	_play_background_motion()

func _ember_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.48, 0.12, 0.9))
	gradient.add_point(1.0, Color(1.0, 0.12, 0.02, 0.0))
	return gradient

func _update_background_pivot() -> void:
	fundo.pivot_offset = fundo.size * 0.5

func _play_background_motion() -> void:
	var motion := create_tween().set_loops()
	motion.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_property(fundo, "scale", Vector2(1.022, 1.022), 9.0)
	motion.tween_property(fundo, "scale", Vector2.ONE, 9.0)

func _connect_button_effects(button: TextureButton) -> void:
	button.pivot_offset = button.custom_minimum_size * 0.5
	button.button_down.connect(EstadoJogo.play_button_sound)
	button.mouse_entered.connect(_animate_button.bind(button, Vector2(1.045, 1.045), 0.14))
	button.mouse_exited.connect(_animate_button.bind(button, Vector2.ONE, 0.16))
	button.button_down.connect(_animate_button.bind(button, Vector2(0.97, 0.97), 0.06))
	button.button_up.connect(_on_button_up.bind(button))

func _on_button_up(button: TextureButton) -> void:
	_animate_button(button, Vector2(1.045, 1.045) if button.is_hovered() else Vector2.ONE, 0.08)

func _animate_button(button: TextureButton, target: Vector2, duration: float) -> void:
	if button_tweens.has(button) and is_instance_valid(button_tweens[button]):
		button_tweens[button].kill()
	var tween := create_tween()
	button_tweens[button] = tween
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target, duration)
	button.modulate = Color(1.16, 1.12, 1.0, 1.0) if button.is_hovered() else Color.WHITE

func _on_play() -> void:
	_transition_to(SCENA_ESCOLHA)

func _on_quit() -> void:
	if transitioning: return
	transitioning = true
	await _fade_out()
	get_tree().quit()

func _transition_to(scene_path: String) -> void:
	if transitioning: return
	if not ResourceLoader.exists(scene_path):
		push_error("Cena não encontrada: %s" % scene_path)
		return
	transitioning = true
	await _fade_out()
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Falha ao abrir cena: %s (%s)" % [scene_path, error])
		transitioning = false
		transicao.modulate.a = 0.0
		transicao.mouse_filter = Control.MOUSE_FILTER_IGNORE
		play.disabled = false
		quit.disabled = false

func _fade_out() -> void:
	if intro and intro.is_running(): intro.kill()
	play.disabled = true
	quit.disabled = true
	transicao.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(transicao, "modulate:a", 1.0, 0.55)
	await tween.finished
