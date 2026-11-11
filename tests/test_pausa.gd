extends SceneTree

## Exercita a interface persistida e confirma que a recarga acontece sob preto completo.
const GAME := "res://scenes/world/labyrinth/labirinto.tscn"
var failures: Array[String] = []
var overlay: CanvasLayer
var changes := 0
var opacity_at_change := -1.0
var paused_at_change := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		printerr(message)

func changed() -> void:
	changes += 1
	opacity_at_change = overlay._fade_screen.color.a
	paused_at_change = paused

func wait_transition() -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while overlay._changing_scene and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not overlay._changing_scene, "Fade não concluiu")

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/" + name + ".png")

func run() -> void:
	change_scene_to_file(GAME)
	await scene_changed
	for i in 4: await process_frame
	overlay = root.get_node("PauseOverlay")
	var game := current_scene
	var original_player: int = game.player.get_instance_id()
	var original_character: String = game.player.name
	overlay._pause_game()
	await process_frame
	check(paused and overlay._pause_panel.visible, "Pausa não abriu")
	check(overlay._ui.scene_file_path.ends_with("/pausa.tscn"), "Interface não usa cena editável")
	check(overlay._pause_panel.get_theme_stylebox("panel") is StyleBoxTexture, "Moldura de pedra ausente")
	var restart: TextureButton = overlay._pause_panel.get_node("Conteudo/Botoes/Reiniciar/Botao")
	check(restart.tooltip_text == "Reiniciar", "Tooltip extenso permaneceu")
	check(restart.get_theme_font_size("font_size", "TooltipLabel") <= 11, "Tooltip ainda grande")
	await capture("pausa_pedra")
	# Hover real para registrar o tamanho do tooltip, sem depender só do tema.
	var motion := InputEventMouseMotion.new()
	motion.position = restart.get_global_rect().get_center()
	root.push_input(motion, true)
	await create_timer(0.8, true).timeout
	await capture("pausa_hover")
	scene_changed.connect(changed)
	restart.pressed.emit()
	restart.pressed.emit()
	await create_timer(0.2, true).timeout
	check(overlay._fade_screen.visible and overlay._fade_screen.color.a > 0.1, "Não escureceu ao reiniciar")
	check(current_scene == game and paused, "Trocou a partida antes do preto")
	await capture("pausa_escurecendo")
	await wait_transition()
	check(changes == 1, "Clique duplicado reiniciou mais de uma vez")
	check(opacity_at_change >= 0.999 and paused_at_change, "Troca ocorreu visível ou com jogo rodando")
	check(current_scene.player.get_instance_id() != original_player, "Partida não foi recriada")
	check(current_scene.player.name == original_character, "Reinício mudou o personagem")
	check(current_scene.current_room in current_scene.Map.START_ROOMS, "Reinício perdeu sorteio de nascimento")
	check(not paused and not overlay._fade_screen.visible, "Fade deixou jogo travado ou coberto")
	await capture("pausa_reiniciado")
	overlay._pause_game()
	overlay._resume_game()
	check(not paused and not overlay._pause_panel.visible, "Continuar não retomou")
	scene_changed.disconnect(changed)
	print("PAUSA_RESULT falhas=", failures)
	quit(0 if failures.is_empty() else 1)
