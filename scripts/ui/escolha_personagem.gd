extends Control

const SCENA_MENU := "res://scenes/ui/menus/MenuInicial.tscn"
const IDS := ["personagem_1", "personagem_2"]
const SECTION_PATCH_RECT := Rect2(390.0, 304.0, 790.0, 101.0)
const GLOW_SHADER := """
shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(1.0, 0.62, 0.16, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float alpha_near = 0.0;
	vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
	alpha_near = max(alpha_near, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	alpha_near = max(alpha_near, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
	alpha_near = max(alpha_near, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	alpha_near = max(alpha_near, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
	alpha_near = max(alpha_near, texture(TEXTURE, UV + px).a);
	alpha_near = max(alpha_near, texture(TEXTURE, UV - px).a);
	alpha_near = max(alpha_near, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	alpha_near = max(alpha_near, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	float silhouette = max(0.0, alpha_near - base.a);
	COLOR = base;
	COLOR.rgb = mix(base.rgb, glow_color.rgb, glow_strength * base.a * 0.18);
	COLOR.a = max(base.a, silhouette * glow_strength * glow_color.a * 0.82);
}
"""

@onready var fundo: TextureRect = $Fundo
@onready var section_background_patch: TextureRect = $Fundo/PatchFaixaIntegrada
@onready var sombra: ColorRect = $Sombra
@onready var personagens_area: ScrollContainer = $Interface/PersonagensArea
@onready var cards: Array = [
	$Interface/PersonagensArea/Personagens/Personagem1,
	$Interface/PersonagensArea/Personagens/Personagem2
]
@onready var status: Label = $Interface/Status
@onready var next_button: TextureButton = $Interface/Next
@onready var back_button: TextureButton = $Interface/Back
@onready var transicao: ColorRect = $Transicao

var personagem_selecionado := ""
var card_hover := ""
var card_tweens: Dictionary = {}
var selected_pulse: Tween
var next_tween: Tween
var selected_sparkles: Array[Label] = []
var sparkle_tweens: Array[Tween] = []
var glow_materials: Dictionary = {}
var glow_tweens: Dictionary = {}
var pulse_character_id := ""
var next_hovered := false
var next_base_scale := Vector2.ONE
var back_hovered := false
var back_base_scale := Vector2.ONE
var back_tween: Tween
var transitioning := false
var intro: Tween

func _ready() -> void:
	EstadoJogo.configurar_tela(true)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	EstadoJogo.register_volume_control(EstadoJogo.add_volume_control(self))
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	section_background_patch.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.resized.connect(_layout_section_background_patch)
	call_deferred("_layout_section_background_patch")
	for index in range(cards.size()):
		var card: Control = cards[index]
		var character_id: String = IDS[index]
		var representation: TextureButton = card.get_node("Conteudo/Representacao")
		representation.pivot_offset = representation.custom_minimum_size * 0.5
		representation.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var glow := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = GLOW_SHADER
		glow.shader = shader
		glow.set_shader_parameter("glow_strength", 0.0)
		glow.set_shader_parameter("glow_color", Color(1.0, 0.62, 0.16, 1.0))
		representation.material = glow
		glow_materials[character_id] = glow
		representation.button_down.connect(EstadoJogo.play_button_sound)
		representation.pressed.connect(_select_character.bind(character_id))
		representation.tooltip_text = _display_name(character_id)
		representation.focus_entered.connect(_on_card_hover.bind(character_id, true))
		representation.focus_exited.connect(_on_card_hover.bind(character_id, false))
		representation.mouse_entered.connect(_on_card_hover.bind(character_id, true))
		representation.mouse_exited.connect(_on_card_hover.bind(character_id, false))
		card.pivot_offset = card.custom_minimum_size * 0.5

	next_button.pivot_offset = next_button.custom_minimum_size * 0.5
	next_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_button.button_down.connect(EstadoJogo.play_button_sound)
	next_button.pressed.connect(_on_next_pressed)
	next_button.mouse_entered.connect(_on_next_hover.bind(true))
	next_button.mouse_exited.connect(_on_next_hover.bind(false))
	back_button.pivot_offset = back_button.custom_minimum_size * 0.5
	back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_button.button_down.connect(EstadoJogo.play_button_sound)
	back_button.pressed.connect(_on_voltar)
	back_button.mouse_entered.connect(_on_back_hover.bind(true))
	back_button.mouse_exited.connect(_on_back_hover.bind(false))
	back_button.button_down.connect(_on_back_pressed_visual)
	back_button.button_up.connect(_on_back_released)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	_start_ambient_flicker()

	transicao.visible = true
	transicao.color = Color.BLACK
	transicao.modulate.a = 1.0
	transicao.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_buttons_disabled(true)
	intro = create_tween()
	intro.tween_property(transicao, "modulate:a", 0.0, 0.35)
	intro.finished.connect(_on_intro_finished)
	if EstadoJogo.PERSONAGENS.has(EstadoJogo.personagem_selecionado):
		_select_character(EstadoJogo.personagem_selecionado)
	else:
		status.text = "Escolha Aelin ou Dorian para começar."
		_update_card_visuals()

func _on_intro_finished() -> void:
	transicao.visible = false
	_set_buttons_disabled(false)
	var index := maxi(IDS.find(personagem_selecionado), 0)
	cards[index].get_node("Conteudo/Representacao").grab_focus()

func _set_buttons_disabled(value: bool) -> void:
	next_button.disabled = value
	back_button.disabled = value
	for card in cards:
		card.get_node("Conteudo/Representacao").disabled = value

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not transitioning:
		get_viewport().set_input_as_handled()
		_on_voltar()

func _on_viewport_size_changed() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 900.0 or viewport_size.y < 560.0
	var short := viewport_size.y < 600.0
	next_base_scale = Vector2(0.82, 0.82) if compact else Vector2.ONE
	next_button.scale = next_base_scale
	back_base_scale = Vector2(0.9, 0.9) if compact else Vector2.ONE
	back_button.scale = back_base_scale
	if short:
		personagens_area.anchor_top = 0.30
		personagens_area.anchor_bottom = 0.59
		status.anchor_top = 0.60
		status.anchor_bottom = 0.65
		next_button.anchor_top = 0.65
		next_button.anchor_bottom = 0.65
		back_button.anchor_top = 0.86
		back_button.anchor_bottom = 0.86
	else:
		personagens_area.anchor_top = 0.39
		personagens_area.anchor_bottom = 0.70
		status.anchor_top = 0.70
		status.anchor_bottom = 0.75
		next_button.anchor_top = 0.75
		next_button.anchor_bottom = 0.75
		back_button.anchor_top = 0.90
		back_button.anchor_bottom = 0.90
	_layout_section_background_patch()

func _layout_section_background_patch() -> void:
	if fundo.texture == null or fundo.size.x <= 0.0 or fundo.size.y <= 0.0:
		return
	var source_size: Vector2 = fundo.texture.get_size()
	var cover_scale: float = maxf(fundo.size.x / source_size.x, fundo.size.y / source_size.y)
	var rendered_size: Vector2 = source_size * cover_scale
	section_background_patch.position = (fundo.size - rendered_size) * 0.5 + SECTION_PATCH_RECT.position * cover_scale
	section_background_patch.size = SECTION_PATCH_RECT.size * cover_scale

func _start_ambient_flicker() -> void:
	var flicker := create_tween().set_loops()
	flicker.tween_property(sombra, "color:a", 0.38, 1.7)
	flicker.tween_property(sombra, "color:a", 0.43, 2.1)

func _on_card_hover(character_id: String, entered: bool) -> void:
	if entered:
		card_hover = character_id
	elif card_hover == character_id:
		card_hover = ""
	_update_card_visuals()

func _select_character(character_id: String) -> void:
	if transitioning or not IDS.has(character_id): return
	personagem_selecionado = character_id
	EstadoJogo.personagem_selecionado = character_id
	status.text = "Selecionado: %s" % _display_name(character_id)
	_update_card_visuals()

func _display_name(character_id: String) -> String:
	match character_id:
		"personagem_1": return "Aelin"
		"personagem_2": return "Dorian"
		_: return "Personagem"

func _update_card_visuals() -> void:
	var selected_card: Control
	for index in range(cards.size()):
		var card: Control = cards[index]
		var character_id: String = IDS[index]
		var selected := character_id == personagem_selecionado
		var hovered := character_id == card_hover
		if selected:
			selected_card = card

		var representation: TextureButton = card.get_node("Conteudo/Representacao")
		if selected:
			representation.modulate = Color(1.07, 1.035, 0.98, 1.0)
		elif hovered:
			representation.modulate = Color(1.045, 1.02, 0.99, 1.0)
		else:
			representation.modulate = Color(0.96, 0.95, 0.92, 1.0)
		_animate_glow(character_id, 0.48 if selected else (0.24 if hovered else 0.0))
		representation.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var target := Vector2(1.035, 1.035) if selected else (Vector2(1.025, 1.025) if hovered else Vector2.ONE)
		_animate_card(card, target)

	_sync_selection_effects(selected_card)

func _animate_glow(character_id: String, strength: float) -> void:
	var material: ShaderMaterial = glow_materials[character_id]
	if glow_tweens.has(character_id) and glow_tweens[character_id].is_running():
		glow_tweens[character_id].kill()
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	glow_tweens[character_id] = tween
	tween.tween_method(func(value: float): material.set_shader_parameter("glow_strength", value), material.get_shader_parameter("glow_strength"), strength, 0.28)

func _animate_card(card: Control, target: Vector2) -> void:
	if card_tweens.has(card) and is_instance_valid(card_tweens[card]):
		card_tweens[card].kill()
	var tween := create_tween()
	card_tweens[card] = tween
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", target, 0.28)

func _sync_selection_effects(card: Control) -> void:
	var next_id: String = "" if card == null else IDS[cards.find(card)]
	if next_id == pulse_character_id:
		return

	if selected_pulse and selected_pulse.is_running():
		selected_pulse.kill()
	if not pulse_character_id.is_empty():
		var previous: Control = cards[IDS.find(pulse_character_id)]
		previous.self_modulate = Color.WHITE
	_clear_selected_particles()
	pulse_character_id = next_id
	if card == null:
		return

	card.self_modulate = Color.WHITE
	selected_pulse = create_tween().set_loops()
	selected_pulse.tween_property(card, "self_modulate", Color(1.055, 1.035, 1.0, 1.0), 0.9)
	selected_pulse.tween_property(card, "self_modulate", Color.WHITE, 0.9)
	_create_selected_particles(card)

func _create_selected_particles(card: Control) -> void:
	var card_size := card.size
	var sparkle_positions := [
		Vector2(14, 22),
		Vector2(card_size.x - 26, 22),
		Vector2(20, card_size.y - 30),
		Vector2(card_size.x - 30, card_size.y - 32)
	]
	for index in range(sparkle_positions.size()):
		var sparkle := Label.new()
		sparkle.text = "✦" if index % 2 == 0 else "✧"
		sparkle.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32, 1.0))
		sparkle.add_theme_font_size_override("font_size", 17 if index % 2 == 0 else 13)
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparkle.z_index = 6
		var origin: Vector2 = sparkle_positions[index]
		sparkle.position = origin
		sparkle.modulate.a = 0.0
		card.add_child(sparkle)

		var tween := create_tween().set_loops()
		tween.tween_interval(index * 0.12)
		tween.tween_property(sparkle, "modulate:a", 0.95, 0.22)
		tween.parallel().tween_property(sparkle, "position:y", origin.y - 12.0, 0.3)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.3)
		tween.parallel().tween_property(sparkle, "position:y", origin.y, 0.3)
		selected_sparkles.append(sparkle)
		sparkle_tweens.append(tween)

func _clear_selected_particles() -> void:
	for tween in sparkle_tweens:
		if tween and tween.is_running():
			tween.kill()
	for sparkle in selected_sparkles:
		if is_instance_valid(sparkle):
			sparkle.queue_free()
	sparkle_tweens.clear()
	selected_sparkles.clear()
func _on_next_hover(entered: bool) -> void:
	next_hovered = entered
	_animate_next_button(next_base_scale * (1.045 if entered else 1.0), Color(1.12, 1.08, 0.96, 1.0) if entered else Color.WHITE, 0.25)

func _on_back_hover(entered: bool) -> void:
	back_hovered = entered
	_animate_back_button(back_base_scale * (1.045 if entered else 1.0), 0.24 if entered else 0.0)

func _on_back_pressed_visual() -> void:
	_animate_back_button(back_base_scale * 0.94, 0.0)

func _on_back_released() -> void:
	_animate_back_button(back_base_scale * (1.045 if back_hovered else 1.0), 0.24 if back_hovered else 0.0)

func _animate_back_button(target_scale: Vector2, glow: float) -> void:
	if back_tween and back_tween.is_running():
		back_tween.kill()
	back_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back_tween.tween_property(back_button, "scale", target_scale, 0.22)
	back_tween.parallel().tween_property(back_button, "modulate", Color(1.12, 1.08, 0.96, 1.0) if glow > 0.0 else Color.WHITE, 0.22)

func _animate_next_button(target_scale: Vector2, tint: Color, duration: float) -> void:
	if next_tween and next_tween.is_running():
		next_tween.kill()
	next_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	next_tween.tween_property(next_button, "scale", target_scale, duration)
	next_tween.parallel().tween_property(next_button, "modulate", tint, duration)

func _on_next_pressed() -> void:
	if transitioning: return
	if next_tween and next_tween.is_running():
		next_tween.kill()
	next_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	next_tween.tween_property(next_button, "scale", next_base_scale * 0.94, 0.08)
	next_tween.tween_property(next_button, "scale", next_base_scale * (1.045 if next_hovered else 1.0), 0.22)
	await _on_confirmar()

func _on_confirmar() -> void:
	if transitioning: return
	if personagem_selecionado.is_empty():
		status.text = "Escolha um personagem antes de continuar."
		return
	EstadoJogo.personagem_selecionado = personagem_selecionado
	var gameplay: String = EstadoJogo.cena_gameplay
	if gameplay.is_empty() or not ResourceLoader.exists(gameplay):
		status.text = "Escolha salva, mas não há cena de gameplay neste projeto."
		return
	await _change_scene(gameplay)

func _on_voltar() -> void:
	if transitioning: return
	await _change_scene(SCENA_MENU)

func _change_scene(path: String) -> void:
	transitioning = true
	await _fade_out()
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		transitioning = false
		transicao.visible = false
		_set_buttons_disabled(false)
		status.text = "Não foi possível abrir a cena. Tente novamente."
		push_error("Falha ao abrir %s: %s" % [path, error])

func _fade_out() -> void:
	if intro and intro.is_running(): intro.kill()
	_set_buttons_disabled(true)
	transicao.visible = true
	transicao.color = Color.BLACK
	transicao.modulate.a = 0.0
	transicao.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(transicao, "modulate:a", 1.0, 0.32)
	await tween.finished
