extends SceneTree

## Verifica colisão real do personagem com o entulho e mantém as entradas livres.
const Game = preload("res://scenes/world/labyrinth/labirinto.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		printerr(message)

func run() -> void:
	var game: Node2D = Game.instantiate()
	root.add_child(game)
	game.player.controls_enabled = false
	game.player.set_physics_process(false)
	game.transitioning = true
	for i in 4: await physics_frame
	var space: PhysicsDirectSpaceState2D = game.player.get_world_2d().direct_space_state
	var obstacles: Array[Node] = game.room.get_node("Entulho").get_children()
	check(obstacles.size() == 17, "Esperados 17 objetos sólidos")
	var hits := 0
	for obstacle: Node2D in obstacles:
		var body: StaticBody2D = obstacle.get_node("CorpoSolido")
		var polygon: CollisionPolygon2D = body.get_node("Base")
		var center := Vector2.ZERO
		for point: Vector2 in polygon.polygon: center += point
		center = polygon.to_global(center / polygon.polygon.size())
		var query := PhysicsPointQueryParameters2D.new()
		query.position = center
		query.collision_mask = 1
		var contacts := space.intersect_point(query)
		check(contacts.any(func(hit: Dictionary): return hit.collider == body), "Base não registrada: " + obstacle.name)
		for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			game.player.global_position = center + direction * 80 - game.player.get_node("CollisionShape2D").position
			var hit: KinematicCollision2D = game.player.move_and_collide(-direction * 160)
			check(hit != null, "Personagem atravessou: " + obstacle.name)
			if hit != null: hits += 1
	print("OBJETOS_RESULT objetos=%s impactos=%s falhas=%s" % [obstacles.size(), hits, failures])
	game.free()
	quit(0 if failures.is_empty() else 1)
