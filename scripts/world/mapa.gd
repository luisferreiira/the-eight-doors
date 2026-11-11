## Mapa fornece dados espaciais a Labirinto, Sala, Porta e à visualização do editor. Não é anexado a um nó.
extends RefCounted
## Coordinates describe a fixed spatial map, not a list of arbitrary teleports.
const DIRECTIONS := {
	"N": Vector2i(0,-1), "NE": Vector2i(1,-1), "L": Vector2i(1,0),
	"SE": Vector2i(1,1), "S": Vector2i(0,1), "SO": Vector2i(-1,1),
	"O": Vector2i(-1,0), "NO": Vector2i(-1,-1)
}
const OPPOSITE := {"N":"S", "NE":"SO", "L":"O", "SE":"NO", "S":"N", "SO":"NE", "O":"L", "NO":"SE"}
const NAMES := {"N":"Norte", "NE":"Nordeste", "L":"Leste", "SE":"Sudeste", "S":"Sul", "SO":"Sudoeste", "O":"Oeste", "NO":"Noroeste"}
const PITCH := Vector2(1440,1216)
const PORTALS := {"N":Vector2(560,192), "NE":Vector2(928,320), "L":Vector2(1056,576), "SE":Vector2(928,832), "S":Vector2(560,960), "SO":Vector2(192,832), "O":Vector2(64,576), "NO":Vector2(192,320)}
const CONTOUR := [Vector2(320,192),Vector2(800,192),Vector2(1056,448),Vector2(1056,704),Vector2(800,960),Vector2(320,960),Vector2(64,704),Vector2(64,448)]
# Conservative envelope includes masonry, torch/decor overhang and the old tunnel.
const ENVELOPE := Rect2(0,0,1120,1024)
const CAMERA_BOUNDS := Rect2(32,16,1056,976)
const CENTER_SPAWN := Vector2(560,640)

## Expansão aprovada: saídas externas não são ligações entre salas.
const EXITS := {"S14":"O", "S21":"N"}
## Inícios seguros aprovados: norte, leste e sul; nunca a sala central ou as saídas.
const START_ROOMS: Array[String] = ["S22", "S23", "S29"]

## Salas com segurança de nascimento marcada apenas nos três inícios aprovados.
## IDs E0/D3–D9 reservam passagens futuras, sem ativar selos ou enigmas.
static func create_rooms() -> Dictionary:
	return {
		"S01": {"coord":Vector2i(0,0), "safe":false, "links":{"N":"S02","NE":"S03","L":"S04","S":"S05","SO":"S06","O":"S10","NO":"S07"}, "blocked":{"L":"E0"}},
		"S02": {"coord":Vector2i(0,-1), "safe":false, "links":{"S":"S01","O":"S07","N":"S15","L":"S03","NE":"S16"}, "blocked":{"NE":"D6"}},
		"S03": {"coord":Vector2i(1,-1), "safe":false, "links":{"SO":"S01","S":"S04","L":"S18","N":"S16","O":"S02","NE":"S17"}, "blocked":{"NE":"D7"}},
		"S04": {"coord":Vector2i(1,0), "safe":false, "links":{"O":"S01","N":"S03","L":"S23","SE":"S26"}, "blocked":{"O":"E0","SE":"D8"}},
		"S05": {"coord":Vector2i(0,1), "safe":false, "links":{"N":"S01","S":"S29","SE":"S28","O":"S06","SO":"S30"}},
		"S06": {"coord":Vector2i(-1,1), "safe":false, "links":{"NE":"S01","O":"S11","N":"S10","S":"S30","L":"S05","NO":"S09"}, "blocked":{"S":"D4"}},
		"S07": {"coord":Vector2i(-1,-1), "safe":false, "links":{"L":"S02","O":"S08","S":"S10","SE":"S01","SO":"S09","NE":"S15"}, "blocked":{"SO":"D5"}},
		"S08": {"coord":Vector2i(-2,-1), "safe":false, "links":{"L":"S07","S":"S09"}},
		"S09": {"coord":Vector2i(-2,0), "safe":false, "links":{"N":"S08","L":"S10","S":"S11","SE":"S06","NE":"S07","SO":"S12"}, "blocked":{"NE":"D5"}},
		"S10": {"coord":Vector2i(-1,0), "safe":false, "links":{"O":"S09","L":"S01","S":"S06","N":"S07"}},
		"S11": {"coord":Vector2i(-2,1), "safe":false, "links":{"N":"S09","O":"S12","L":"S06"}},
		"S12": {"coord":Vector2i(-3,1), "safe":false, "links":{"L":"S11","N":"S13","NE":"S09"}},
		"S13": {"coord":Vector2i(-3,0), "safe":false, "links":{"S":"S12","N":"S14"}},
		"S14": {"coord":Vector2i(-3,-1), "safe":false, "links":{"S":"S13"}},
		"S15": {"coord":Vector2i(0,-2), "safe":false, "links":{"S":"S02","L":"S16","SO":"S07"}},
		"S16": {"coord":Vector2i(1,-2), "safe":false, "links":{"O":"S15","L":"S17","N":"S22","S":"S03","SO":"S02"}, "blocked":{"SO":"D6"}},
		"S17": {"coord":Vector2i(2,-2), "safe":false, "links":{"O":"S16","S":"S18","SO":"S03"}, "blocked":{"SO":"D7"}},
		"S18": {"coord":Vector2i(2,-1), "safe":false, "links":{"N":"S17","L":"S19","O":"S03"}},
		"S19": {"coord":Vector2i(3,-1), "safe":false, "links":{"O":"S18","N":"S20"}},
		"S20": {"coord":Vector2i(3,-2), "safe":false, "links":{"S":"S19","N":"S21"}},
		"S21": {"coord":Vector2i(3,-3), "safe":false, "links":{"S":"S20"}},
		"S22": {"coord":Vector2i(1,-3), "safe":true, "links":{"S":"S16"}},
		"S23": {"coord":Vector2i(2,0), "safe":true, "links":{"O":"S04","L":"S24","S":"S26"}, "blocked":{"S":"D3"}},
		"S24": {"coord":Vector2i(3,0), "safe":false, "links":{"O":"S23","S":"S25","SO":"S26"}},
		"S25": {"coord":Vector2i(3,1), "safe":false, "links":{"N":"S24","O":"S26","SO":"S27"}, "blocked":{"SO":"D9"}},
		"S26": {"coord":Vector2i(2,1), "safe":false, "links":{"L":"S25","S":"S27","NE":"S24","N":"S23","NO":"S04"}, "blocked":{"N":"D3","NO":"D8"}},
		"S27": {"coord":Vector2i(2,2), "safe":false, "links":{"N":"S26","O":"S28","NE":"S25"}, "blocked":{"NE":"D9"}},
		"S28": {"coord":Vector2i(1,2), "safe":false, "links":{"L":"S27","O":"S29","NO":"S05"}},
		"S29": {"coord":Vector2i(0,2), "safe":true, "links":{"L":"S28","O":"S30","N":"S05"}},
		"S30": {"coord":Vector2i(-1,2), "safe":false, "links":{"L":"S29","N":"S06","NE":"S05"}, "blocked":{"N":"D4"}},
	}

## Converte a coordenada lógica em pixels pelo passo físico, preservando alinhamento e espaço entre salas.
static func origin(config: Dictionary) -> Vector2:
	return Vector2(config.coord) * PITCH

## Converte o envelope retangular em polígono para consultar interseções geométricas.
static func rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

## Retorna a faixa de 80 pixels entre dois portais; representa uma passagem implícita, sem arte navegável.
static func passage(a: Vector2, b: Vector2) -> PackedVector2Array:
	var side := (b-a).normalized().orthogonal() * 40.0
	return PackedVector2Array([a+side,b+side,b-side,a-side])

## Retorna mensagens de erro para coordenadas repetidas, destinos, retornos, alinhamentos e sobreposições. Lista vazia indica mapa coerente.
static func validate(rooms: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var occupied := {}
	var corridors: Array[Dictionary] = []
	for id: String in rooms:
		var config: Dictionary = rooms[id]
		if occupied.has(config.coord): errors.append("Coordenada duplicada: " + id)
		occupied[config.coord] = id
		# Expansão: um bloqueio precisa corresponder a uma conexão nas duas faces.
		for direction: String in config.get("blocked", {}):
			if not config.links.has(direction):
				errors.append("Bloqueio sem conexao: " + id + direction)
		# Saídas externas não podem disputar a mesma porta com uma ligação interna.
		if EXITS.has(id) and config.links.has(EXITS[id]):
			errors.append("Saida ocupada por conexao interna: " + id)
		for direction: String in config.links:
			var target: String = config.links[direction]
			if not DIRECTIONS.has(direction):
				errors.append("Direcao desconhecida: " + direction)
				continue
			if not rooms.has(target):
				errors.append("Destino inexistente: " + target)
				continue
			if rooms[target].coord != config.coord + DIRECTIONS[direction]: errors.append("Direcao incompativel: " + id + direction)
			if rooms[target].links.get(OPPOSITE[direction], "") != id: errors.append("Sem retorno: " + id + direction)
			# A grade fechada deve impedir ida e volta do mesmo atalho.
			if config.get("blocked", {}).get(direction, "") != rooms[target].get("blocked", {}).get(OPPOSITE[direction], ""):
				errors.append("Bloqueio sem correspondencia: " + id + direction)
			var a: Vector2 = origin(config) + PORTALS[direction]
			var b: Vector2 = origin(rooms[target]) + PORTALS[OPPOSITE[direction]]
			var normal := Vector2(DIRECTIONS[direction]).normalized()
			if (b-a).dot(normal) <= 0 or absf((b-a).cross(normal)) > 0.01: errors.append("Passagem desalinhada: " + id + direction)
			if id < target: corridors.append({"from":id,"to":target,"polygon":passage(a,b)})
	var ids := rooms.keys()
	for i in ids.size():
		var envelope := Rect2(origin(rooms[ids[i]]) + ENVELOPE.position, ENVELOPE.size)
		for j in range(i+1,ids.size()):
			if envelope.intersects(Rect2(origin(rooms[ids[j]])+ENVELOPE.position,ENVELOPE.size)):
				errors.append("Salas sobrepostas: " + ids[i] + "/" + ids[j])
		for corridor in corridors:
			if ids[i] not in [corridor.from,corridor.to] and not Geometry2D.intersect_polygons(rect_polygon(envelope),corridor.polygon).is_empty():
				errors.append("Passagem atravessa sala: " + ids[i])
	for i in corridors.size():
		for j in range(i+1,corridors.size()):
			if not Geometry2D.intersect_polygons(corridors[i].polygon,corridors[j].polygon).is_empty(): errors.append("Passagens cruzadas")
	return errors
