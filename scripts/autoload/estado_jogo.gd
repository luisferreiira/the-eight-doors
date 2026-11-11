extends Node

## Estado compartilhado pelas telas e pelo labirinto. IDs da seleção original.
const PERSONAGENS := {
	"personagem_1": preload("res://scenes/characters/players/aelin.tscn"),
	"personagem_2": preload("res://scenes/characters/players/dorian.tscn")
}
const MENU := "res://scenes/ui/menus/MenuInicial.tscn"

const MUSIC_PATH := "res://assets/audio/music/trilhaSonora.mp3"
const BUTTON_SOUND_PATH := "res://assets/audio/sfx/botao.mp3"
const VOLUME_ICON_PATHS := [
	"res://assets/ui/volume_maximo.png",
	"res://assets/ui/volume_medio.png",
	"res://assets/ui/volume_mudo.png"
]
const VOLUME_DB := [0.0, -6.0206, -80.0]

var _music_player: AudioStreamPlayer
var _button_player: AudioStreamPlayer
var _volume_icons: Array[Texture2D] = []
var _volume_level := 0

var personagem_selecionado: String = ""
var cena_gameplay: String = "res://scenes/world/labyrinth/labirinto.tscn"

func cena_personagem() -> PackedScene:
	return PERSONAGENS.get(personagem_selecionado) as PackedScene

func configurar_tela(menu: bool) -> void:
	# Menus conservam o desenho em 1280x720; gameplay mantém câmera/pixels em 640x360.
	get_tree().root.content_scale_size = Vector2i(1280, 720) if menu else Vector2i(640, 360)
	ensure_menu_music()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MenuMusic"
	_music_player.stream = load(MUSIC_PATH)
	var music_stream := _music_player.stream as AudioStreamMP3
	if music_stream != null:
		music_stream.loop = true
	add_child(_music_player)

	_button_player = AudioStreamPlayer.new()
	_button_player.name = "ButtonSound"
	_button_player.stream = load(BUTTON_SOUND_PATH)
	_button_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_button_player)
	for icon_path in VOLUME_ICON_PATHS:
		_volume_icons.append(load(icon_path) as Texture2D)
	_apply_volume()

func ensure_menu_music() -> void:
	if _music_player != null and not _music_player.playing:
		_music_player.play()

func play_button_sound() -> void:
	if _button_player != null:
		_button_player.play()

func add_volume_control(parent: Control, ui_scale: float = 1.0) -> TextureButton:
	var volume_button := TextureButton.new()
	volume_button.name = "VolumeControl"
	volume_button.anchor_left = 1.0
	volume_button.anchor_right = 1.0
	volume_button.anchor_top = 0.0
	volume_button.anchor_bottom = 0.0
	volume_button.offset_left = -148.0 * ui_scale
	volume_button.offset_top = 16.0 * ui_scale
	volume_button.offset_right = -16.0 * ui_scale
	volume_button.offset_bottom = 80.0 * ui_scale
	volume_button.ignore_texture_size = true
	volume_button.stretch_mode = TextureButton.STRETCH_SCALE
	volume_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	volume_button.z_index = 10
	parent.add_child(volume_button)
	volume_button.button_down.connect(play_button_sound)
	volume_button.pressed.connect(_cycle_volume)
	_update_volume_icon(volume_button)
	return volume_button

func _cycle_volume() -> void:
	_volume_level = (_volume_level + 1) % VOLUME_DB.size()
	_apply_volume()
	for node in get_tree().get_nodes_in_group("volume_controls"):
		if is_instance_valid(node):
			_update_volume_icon(node as TextureButton)

func _apply_volume() -> void:
	var volume_db: float = VOLUME_DB[_volume_level]
	if _music_player != null:
		_music_player.volume_db = volume_db
	if _button_player != null:
		_button_player.volume_db = volume_db

func _update_volume_icon(button: TextureButton) -> void:
	if _volume_icons.size() != VOLUME_ICON_PATHS.size():
		return
	var icon: Texture2D = _volume_icons[_volume_level]
	button.texture_normal = icon
	button.texture_hover = icon
	button.texture_pressed = icon
	button.tooltip_text = ["Volume máximo", "Volume médio", "Sem volume"][_volume_level]

func register_volume_control(button: TextureButton) -> void:
	button.add_to_group("volume_controls")

## Conecta um controle de volume já desenhado na cena, preservando tamanho e layout.
func bind_volume_control(button: TextureButton) -> void:
	register_volume_control(button)
	button.button_down.connect(play_button_sound)
	button.pressed.connect(_cycle_volume)
	_update_volume_icon(button)
