extends SceneTree
var falhas: Array[String]=[]
func exigir(c: bool,m: String) -> void:
	if not c:falhas.append(m)
func _initialize() -> void:call_deferred("_validar")
func caminhos(sala: Node2D,raio: float) -> Dictionary:
	var consulta := sala.get_world_2d().direct_space_state
	var grade := AStarGrid2D.new();grade.region=Rect2i(-4,-4,80,72)
	grade.cell_size=Vector2(16,16);grade.offset=Vector2(8,8)
	grade.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grade.update()
	var poly := PackedVector2Array([Vector2(320,184),Vector2(800,184),Vector2(1056,440),Vector2(1056,696),Vector2(800,952),Vector2(320,952),Vector2(64,696),Vector2(64,440)])
	var circulo := CircleShape2D.new();circulo.radius=raio
	var q := PhysicsShapeQueryParameters2D.new();q.shape=circulo;q.collision_mask=1
	for y: int in range(-4,68):
		for x: int in range(-4,76):
			var id := Vector2i(x,y);var pos := Vector2(id)*16+Vector2(8,8)
			var dentro := Geometry2D.is_point_in_polygon(pos,poly)
			for e: Marker2D in sala.get_node("Entradas").get_children():
				if pos.distance_to(e.position)<48:dentro=true
			q.transform=Transform2D(0,pos)
			grade.set_point_solid(id,not dentro or not consulta.intersect_shape(q,1).is_empty())
	var resultado := {}
	for e: Marker2D in sala.get_node("Entradas").get_children():
		var rota := grade.get_id_path(Vector2i(35,34),Vector2i((e.position/16).floor()))
		resultado[str(e.name)]=rota.size()
		exigir(not rota.is_empty(),"Acesso bloqueado para diametro "+str(raio*2)+": "+str(e.name))
	return resultado
func _validar() -> void:
	var recurso := load("res://scenes/dungeon/sala_central_referencia.tscn") as PackedScene
	exigir(recurso!=null,"Cena nao carrega")
	if recurso==null:quit(1);return
	var sala := recurso.instantiate() as Node2D
	root.add_child(sala)
	await physics_frame;await physics_frame
	var ts := (sala.get_node("Piso") as TileMapLayer).tile_set
	exigir(ts.tile_size==Vector2i(16,16),"Grade-base incorreta")
	for i: int in range(ts.get_source_count()):
		var src := ts.get_source(ts.get_source_id(i)) as TileSetAtlasSource
		exigir(src.texture_region_size==Vector2i(16,16),"Regiao de fonte fora de 16x16")
		exigir(not src.has_tiles_outside_texture(),"Recorte fora de uma textura")
	var celulas := {};var ownership := true
	for n: Node in sala.find_children("*","",true,false):
		if n.owner!=sala:ownership=false;falhas.append("Owner incorreto: "+str(sala.get_path_to(n)))
		exigir(not n.has_meta("_edit_lock_") and not n.has_meta("_edit_group_"),"No bloqueado: "+str(n.name))
		exigir(n.scene_file_path.is_empty(),"Subcena restringe edicao: "+str(n.name))
		if n.get_script():exigir(n is Camera2D,"Geracao associada em runtime")
		if n is TileMapLayer:
			celulas[str(n.name)]=n.get_used_cells().size()
			for c: Vector2i in n.get_used_cells():
				var src := ts.get_source(n.get_cell_source_id(c)) as TileSetAtlasSource
				exigir(src.get_tile_size_in_atlas(n.get_cell_atlas_coords(c))==Vector2i.ONE,"Estampa grande permanece: "+str(n.name))
	exigir(sala.get_node("Elementos/Colunas").get_child_count()==4,"Colunas independentes ausentes")
	exigir(sala.get_node("Elementos/Tochas").get_child_count()==8,"Tochas independentes ausentes")
	exigir(sala.get_node("Elementos/Teias").get_child_count()==4,"Teias mal organizadas")
	exigir(sala.get_node("Entulho").get_child_count()==17,"Entulho ausente")
	exigir(sala.get_node("Elementos/GradeCentral") is Sprite2D,"Grade central nao e objeto editavel")
	exigir(sala.get_node("Entradas").get_child_count()==8,"Numero de entradas incorreto")
	var consulta := sala.get_world_2d().direct_space_state
	for p: Vector2 in [Vector2(400,422),Vector2(720,422),Vector2(400,774),Vector2(720,774),Vector2(64,480),Vector2(64,672),Vector2(1056,480),Vector2(1056,672)]:
		var ponto := PhysicsPointQueryParameters2D.new();ponto.position=p;ponto.collision_mask=1
		exigir(not consulta.intersect_point(ponto).is_empty(),"Base sem colisao: "+str(p))
	for e: Marker2D in sala.get_node("Entradas").get_children():
		var d := (e.position-Vector2(560,576)).normalized()
		var q := PhysicsRayQueryParameters2D.create(e.position-d*24,e.position+d*24,1)
		exigir(consulta.intersect_ray(q).is_empty(),"Vao com colisao: "+str(e.name))
	var rotas16 := caminhos(sala,8)
	var rotas32 := caminhos(sala,16)
	# Persist editing in a separate copy. Never save changes over the production scene.
	var parede := sala.get_node("Paredes") as TileMapLayer
	var ac := (ts.get_source(3) as TileSetAtlasSource).get_tile_id(0)
	var pintar := Vector2i(35,34);var apagar := parede.get_used_cells()[0]
	parede.set_cell(pintar,3,ac);parede.erase_cell(apagar)
	var coluna := sala.get_node("Elementos/Colunas/ColunaNO") as StaticBody2D
	var pos_inicial := coluna.position;coluna.position+=Vector2(16,0)
	var camera := sala.get_node("Camera2D") as Camera2D
	camera.set("enquadramento_automatico",false);camera.position=Vector2(123,456)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://validacao"))
	var editada := PackedScene.new();exigir(editada.pack(sala)==OK,"Falha ao salvar copia")
	exigir(ResourceSaver.save(editada,"res://validacao/edicao_temporaria.tscn")==OK,"Falha ao gravar edicao")
	var copia := (load("res://validacao/edicao_temporaria.tscn") as PackedScene).instantiate()
	root.add_child(copia)
	for i: int in range(6):await process_frame
	var pintura_ok: bool=(copia.get_node("Paredes") as TileMapLayer).get_cell_source_id(pintar)==3
	var apagar_ok: bool=(copia.get_node("Paredes") as TileMapLayer).get_cell_source_id(apagar)==-1
	var mover_ok: bool=(copia.get_node("Elementos/Colunas/ColunaNO") as Node2D).position==pos_inicial+Vector2(16,0)
	var camera_ok: bool=(copia.get_node("Camera2D") as Camera2D).position==Vector2(123,456)
	exigir(pintura_ok,"Pintura revertida");exigir(apagar_ok,"Apagamento revertido");exigir(mover_ok,"Movimento revertido");exigir(camera_ok,"Camera manual reenquadrada")
	exigir(copia.get_node("Elementos/Colunas/ColunaNO/BasePilar1").owner==copia,"Base nao acompanha coluna")
	copia.queue_free()
	var relatorio := {"godot":Engine.get_version_info(),"celulas_por_camada":celulas,"owners_corretos":ownership,"pintar_apagar_mover_salvar_reabrir":pintura_ok and apagar_ok and mover_ok,"camera_manual_preservada":camera_ok,"rotas_diametro16":rotas16,"rotas_diametro32":rotas32,"falhas":falhas}
	FileAccess.open("res://validacao_refino.json",FileAccess.WRITE).store_string(JSON.stringify(relatorio,"\t"))
	for f: String in falhas:push_error(f)
	print("VALIDACAO_REFINO ",JSON.stringify(relatorio))
	quit(0 if falhas.is_empty() else 1)

