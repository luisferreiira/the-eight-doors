extends SceneTree

## Exercita a interação real, erro, cancelamento, animação e persistência nas duas faces.
const Game = preload("res://scenes/world/labyrinth/labirinto.tscn")
var failures: Array[String] = []
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, text: String) -> void:
	if not ok:
		failures.append(text)
		printerr(text)

func frames(n: int = 3) -> void:
	for i in n: await physics_frame

func action(name: String) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	root.push_input(event)
	await frames()
	event = InputEventAction.new()
	event.action = name
	root.push_input(event)

func select(names: Array) -> void:
	for name: String in names:
		game.seal_panel.choices.get_node(name).pressed.emit()
	game.seal_panel.confirm_button.pressed.emit()

func run() -> void:
	game = Game.instantiate()
	# Cenário fixo para testar navegação e E0; nascimentos têm teste próprio.
	game.random_spawn = false
	root.add_child(game)
	await frames()
	var door: Area2D = game.room.doors.L
	# O batente original não deve cobrir a moldura vinho.
	check(not door.get_node("BatenteSuperior").visible, "Batente leste original sobrepõe vinho")
	await action("interact")
	check(not game.seal_panel.visible, "Painel abriu longe da porta")
	game.player.global_position = door.spawn_position()
	await action("interact")
	check(game.seal_panel.visible and not game.player.controls_enabled, "E não abriu inscrição modal")
	check(game.seal_panel.confirm_button.disabled, "Sequência incompleta habilitou confirmação")
	# Captura opcional para conferir a composição do painel no renderer real.
	if "--capture" in OS.get_cmdline_user_args():
		game.camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/primeiro_desafio.png")
	await action("ui_cancel")
	check(not game.seal_panel.visible and game.player.controls_enabled and not paused, "Esc não fechou corretamente")
	await action("interact")
	game.seal_panel.actions.get_node("Fechar").pressed.emit()
	check(not door.opened and game.solved_challenges.is_empty(), "Cancelar alterou progresso")
	await action("interact")
	select(["Sol", "Lua", "Estrela"])
	check(not door.opened and game.seal_panel.sequence.is_empty(), "Resposta errada abriu a porta")
	select(["Estrela", "Lua", "Sol"])
	check(door.opening and not door.opened and game.unlocking, "Colisão liberada antes da animação")
	check(not game.player.controls_enabled and game.blocks_pause(), "Controles liberados durante abertura")
	await create_timer(0.85).timeout
	check(door.opened and game.solved_challenges.has("E0"), "Solução não abriu E0")
	check(door.get_node("PlanoDaPorta/BloqueioFechado/Forma").disabled, "Colisão permaneceu fechada")
	check(not door.get_node("VisualEspecial/Grade").visible, "Sobreposição da grade permaneceu visível")
	game.entry_lock = null
	game.request_transition(door, game.player)
	await create_timer(2.4).timeout
	check(game.current_room == "S04" and game.room.doors.O.opened, "Travessia não restaurou face oposta")
	check(not game.room.doors.SE.opened, "Solução abriu outro desafio")
	game.load_room("S01")
	await frames()
	check(game.room.doors.L.opened, "Retorno esqueceu progresso")
	game.free()
	# Uma nova partida limpa o progresso e permite resolver pelo lado oeste da S04.
	game = Game.instantiate()
	# Cenário fixo para testar navegação e E0; nascimentos têm teste próprio.
	game.random_spawn = false
	root.add_child(game)
	await frames()
	check(not game.room.doors.L.opened and game.solved_challenges.is_empty(), "Nova partida herdou progresso")
	game.load_room("S04")
	check(not game.room.doors.O.get_node("BatenteSuperior").visible, "Batente oeste original sobrepõe vinho")
	await frames()
	game.player.global_position = game.room.doors.O.spawn_position()
	await action("interact")
	select(["Estrela", "Lua", "Sol"])
	await create_timer(0.85).timeout
	check(game.room.doors.O.opened, "Não resolveu pelo outro lado")
	game.load_room("S02")
	await frames()
	game.player.global_position = game.room.doors.NE.spawn_position()
	await action("interact")
	check(not game.seal_panel.visible, "Outro atalho ativou o desafio E0")
	game.free()
	print("PRIMEIRO_DESAFIO_RESULT falhas=", failures)
	quit(0 if failures.is_empty() else 1)
