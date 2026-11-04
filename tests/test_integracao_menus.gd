extends SceneTree
## Executar com --headless --path . --script tests/test_integracao_menus.gd.
## Sem --headless, acrescentar -- --capture para salvar as telas renderizadas.
const OUT := "res://docs/history/integracao_menus_2026-11-03/"
const MENU := "res://scenes/ui/menus/MenuInicial.tscn"
const CHOICE := "res://scenes/ui/menus/EscolhaPersonagem.tscn"
var failures: Array[String] = []
var checks := 0
var state: Node
var overlay: CanvasLayer

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr(message)

func frames(count: int = 4) -> void:
	for i in count: await process_frame

func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout

func click(button: BaseButton) -> void:
	# Envia mouse pelo viewport para validar hit testing e sobreposições reais.
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = down
		root.push_input(event, true)
		await frames(1)

func capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")

func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	Input.parse_input_event(event)
	await frames()

func assert_layout() -> void:
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var buttons := current_scene.find_children("*", "BaseButton", true, false)
	for button: BaseButton in buttons:
		check(screen.encloses(button.get_global_rect()), "Botão fora da tela: " + str(button.get_path()))
	var area: ScrollContainer = current_scene.get_node("Interface/PersonagensArea")
	check(area.get_h_scroll_bar().max_value <= area.size.x + 1.0, "Seleção exige rolagem horizontal")
	check(area.get_v_scroll_bar().max_value <= area.size.y + 1.0, "Seleção recorta personagens")
	check(not current_scene.next_button.get_global_rect().intersects(current_scene.back_button.get_global_rect()), "Next sobrepõe Back")

func run() -> void:
	state = root.get_node("EstadoJogo")
	overlay = root.get_node("PauseOverlay")
	state.personagem_selecionado = ""
	check(ProjectSettings.get_setting("application/run/main_scene") == MENU, "F5 deve abrir menu")
	change_scene_to_file(MENU)
	await wait_seconds(1.2)
	check(current_scene.scene_file_path == MENU, "Menu não abriu")
	check(root.content_scale_size == Vector2i(1280, 720), "Resolução do menu incorreta")
	check(not overlay._ui.visible, "Pausa visível no menu")
	check(state._music_player.playing, "Trilha não iniciou")
	await escape()
	check(not paused, "Esc pausou o menu")
	await capture("01_menu")
	await click(current_scene.play)
	current_scene.play.pressed.emit() # Cliques duplicados não podem criar duas trocas.
	await wait_seconds(1.1)
	check(current_scene.scene_file_path == CHOICE, "Play não abriu escolha")
	current_scene.next_button.pressed.emit()
	await wait_seconds(0.5)
	check(current_scene.scene_file_path == CHOICE, "Next sem seleção iniciou o jogo")
	check(not current_scene.transitioning, "Seleção vazia travou a tela")
	for window_size: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(800,600), Vector2i(640,360)]:
		root.size = window_size
		await frames(6)
		assert_layout()
	root.size = Vector2i(1280, 720)
	await frames()
	await capture("02_escolha")
	for id: String in ["personagem_1", "personagem_2"]:
		var index := 0 if id == "personagem_1" else 1
		var expected := "Aelin" if index == 0 else "Dorian"
		await click(current_scene.cards[index].get_node("Conteudo/Representacao"))
		await wait_seconds(0.35)
		check(state.personagem_selecionado == id, "Escolha não chegou ao estado")
		await capture("03_selecao_" + expected)
		current_scene.back_button.pressed.emit()
		await wait_seconds(1.5)
		check(current_scene.scene_file_path == MENU, "Back não voltou ao menu")
		current_scene.play.pressed.emit()
		await wait_seconds(1.1)
		check(current_scene.personagem_selecionado == id, "Escolha perdida ao voltar")
		await click(current_scene.next_button)
		current_scene.next_button.pressed.emit()
		await wait_seconds(0.8)
		var game := current_scene
		check(game.player.name == expected, "Instanciou personagem errado: " + expected)
		check(root.content_scale_size == Vector2i(640,360), "Câmera perdeu resolução de gameplay")
		check(game.current_room == "S01", "Início fora da sala S01")
		check(game.find_children("*", "CharacterBody2D", true, false).size() == 1, "Jogador duplicado")
		check(overlay._ui.visible, "Pausa ausente no gameplay")
		await capture("04_jogo_" + expected)
		var initial: Vector2 = game.player.position
		await escape()
		check(paused and overlay._pause_panel.visible, "Esc não pausou")
		Input.action_press("move_right")
		await wait_seconds(0.15)
		Input.action_release("move_right")
		check(game.player.position == initial, "Jogador moveu durante pausa")
		await capture("05_pausa_" + expected)
		var music_id: int = state._music_player.get_instance_id()
		for level in [1, 2, 0]:
			await click(overlay._shade.get_node("VolumeControl"))
			check(state._volume_level == level, "Ciclo de volume incorreto")
			for button in get_nodes_in_group("volume_controls"):
				check(button.texture_normal == state._volume_icons[level], "Ícone de volume dessincronizado")
		await escape()
		check(not paused, "Esc não retomou")
		Input.action_press("move_right")
		await wait_seconds(0.2)
		Input.action_release("move_right")
		check(game.player.position.distance_to(initial) > 10.0, "Movimento não retomou")
		var player_id: int = game.player.get_instance_id()
		game.request_transition(game.room.doors["N"], game.player)
		overlay._pause_game()
		check(not paused, "Pausa interrompeu fade")
		check(game.fade.layer > overlay.layer, "Pausa sobrepõe fade")
		await wait_seconds(2.2)
		check(game.current_room == "S02", "Travessia não concluiu")
		check(game.player.get_instance_id() == player_id, "Travessia recriou personagem")
		overlay._pause_game()
		overlay._restart_current_scene()
		overlay._restart_current_scene()
		await wait_seconds(0.6)
		check(not paused and current_scene.current_room == "S01", "Reinício não restabeleceu partida")
		check(current_scene.player.name == expected, "Reinício perdeu personagem")
		check(current_scene.player.get_instance_id() != player_id, "Reinício reutilizou partida antiga")
		check(state._music_player.get_instance_id() == music_id, "Música duplicada")
		overlay._pause_game()
		overlay._return_to_menu()
		await wait_seconds(1.3)
		check(not paused and not overlay._ui.visible, "Pausa vazou ao menu")
		current_scene.play.pressed.emit()
		await wait_seconds(1.1)
	await escape()
	await wait_seconds(1.4)
	check(current_scene.scene_file_path == MENU, "Esc na seleção não voltou")
	state.personagem_selecionado = "invalido"
	change_scene_to_file(state.cena_gameplay)
	await wait_seconds(0.4)
	check(current_scene.player.name == "Aelin", "Seleção inválida não usa personagem padrão")
	var report := {"checks": checks, "failures": failures, "characters": ["Aelin", "Dorian"]}
	FileAccess.open(OUT + "testes_integracao.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("INTEGRACAO_MENUS ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
