extends SceneTree
## Ferramenta opcional: reconstrói SOMENTE os recursos novos desta entrega.
const DIR := "res://assets/generated/dungeon_central/"
const CENA := "res://scenes/dungeon/sala_central_referencia.tscn"
var sala: Node2D

func _initialize() -> void:
	call_deferred("_montar")

func novo(tipo: String, nome: String, pai: Node) -> Node:
	var no := ClassDB.instantiate(tipo) as Node
	no.name = nome
	pai.add_child(no)
	no.owner = sala
	return no

func _montar() -> void:
	if FileAccess.file_exists(CENA):
		print("CENA_EXISTENTE_PRESERVADA: o gerador nao sobrescreve edicoes manuais.")
		quit(0)
		return
	var manifesto: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "atlas_manifesto.json"))
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(DIR + "atlas_sala_central.png")
	atlas.texture_region_size = Vector2i(16, 16)
	var tipos: Dictionary = manifesto.sprites
	for nome: String in tipos:
		var regiao: Array = tipos[nome].atlas
		var coord := Vector2i(int(regiao[0]), int(regiao[1]))
		var tamanho := Vector2i(int(regiao[2]), int(regiao[3]))
		atlas.create_tile(coord, tamanho)
		var dados := atlas.get_tile_data(coord, 0)
		# O ponto da célula ancora o canto superior esquerdo do recorte grande.
		dados.texture_origin = -Vector2i((tamanho.x * 16 - 16) / 2, (tamanho.y * 16 - 16) / 2)
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(16, 16)
	tiles.add_source(atlas, 0)
	var erro := ResourceSaver.save(tiles, DIR + "sala_central_tileset.tres")
	if erro != OK:
		push_error("Não foi possível salvar o TileSet: " + str(erro))
		quit(1)
		return
	sala = Node2D.new()
	sala.name = "SalaCentralReferencia"
	sala.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sala.set_meta("centro_jogavel", Vector2(560, 544))
	sala.set_meta("grade_base", Vector2i(16, 16))
	sala.set_meta("originais_preservados", true)
	var fundo := novo("Polygon2D", "Fundo", sala) as Polygon2D
	fundo.polygon = PackedVector2Array([Vector2(-2000,-2000),Vector2(3000,-2000),Vector2(3000,3000),Vector2(-2000,3000)])
	fundo.color = Color("0c0b10")
	for nome: String in manifesto.layers:
		var camada := novo("TileMapLayer", nome, sala) as TileMapLayer
		camada.tile_set = tiles
		camada.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		for item: Dictionary in manifesto.layers[nome]:
			var recorte: Array = tipos[item.name].atlas
			camada.set_cell(Vector2i(int(item.cell[0]),int(item.cell[1])),0,Vector2i(int(recorte[0]),int(recorte[1])))
		camada.set_meta("quantidade_de_pecas", manifesto.layers[nome].size())
		camada.set_meta("colisoes", "Corpos estáticos em Colisoes; piso e entradas livres.")
	# Somente bases sólidas bloqueiam o jogador; o desenho alto dos sprites fica livre.
	var fisica := novo("StaticBody2D", "Colisoes", sala) as StaticBody2D
	fisica.collision_layer = 1
	fisica.collision_mask = 1
	for parede: Dictionary in manifesto.wall_colliders:
		var forma := novo("CollisionPolygon2D", parede.name, fisica) as CollisionPolygon2D
		var pontos := PackedVector2Array()
		for p: Array in parede.polygon: pontos.append(Vector2(float(p[0]),float(p[1])))
		forma.polygon = pontos
	for i: int in range(manifesto.pillars.size()):
		var p: Array = manifesto.pillars[i]
		var forma := novo("CollisionPolygon2D", "BasePilar" + str(i+1), fisica) as CollisionPolygon2D
		var x := float(p[0]); var y := float(p[1])
		forma.polygon = PackedVector2Array([Vector2(x+8,y+110),Vector2(x+56,y+110),Vector2(x+56,y+126),Vector2(x+8,y+126)])
	var entradas := novo("Node2D", "Entradas", sala) as Node2D
	for passagem: Dictionary in manifesto.passages:
		var ponto := novo("Marker2D", "Saida" + passagem.direction, entradas) as Marker2D
		ponto.position = Vector2(float(passagem.position[0]),float(passagem.position[1]))
		ponto.set_meta("direcao", passagem.direction)
		ponto.set_meta("largura_livre", passagem.width)
	var iluminacao := novo("Node2D", "Iluminacao", sala) as Node2D
	var ambiente := novo("CanvasModulate", "Ambiente", iluminacao) as CanvasModulate
	ambiente.color = Color(0.76,0.74,0.76,1)
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color(1,1,1,0.8))
	gradiente.set_color(1, Color(1,1,1,0))
	var halo := GradientTexture2D.new()
	halo.gradient = gradiente
	halo.width = 256
	halo.height = 256
	halo.fill = GradientTexture2D.FILL_RADIAL
	halo.fill_from = Vector2(0.5,0.5)
	halo.fill_to = Vector2(1,0.5)
	for i: int in range(manifesto.torches.size()):
		var p: Array = manifesto.torches[i]
		var luz := novo("PointLight2D", "LuzTocha"+str(i+1), iluminacao) as PointLight2D
		luz.position = Vector2(float(p[0])+14,float(p[1])+20)
		luz.texture = halo
		luz.color = Color(1.0,0.62,0.31,1)
		luz.energy = 0.62
		luz.texture_scale = 0.95
	var camera := novo("Camera2D", "Camera2D", sala) as Camera2D
	camera.position = Vector2(560,512)
	camera.zoom = Vector2(0.96,0.96)
	camera.set_script(load("res://scripts/camera/camera_sala_central.gd"))
	var cena := PackedScene.new()
	erro = cena.pack(sala)
	if erro == OK: erro = ResourceSaver.save(cena, CENA)
	if erro != OK:
		push_error("Erro ao salvar a nova cena: " + str(erro))
		quit(1)
		return
	print("CENA_CRIADA ",CENA," | TileSet 16x16 | 8 entradas | 4 pilares")
	sala.free()
	quit(0)
