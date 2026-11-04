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

## Retorna configurações independentes: coordenada lógica, segurança de spawn e destinos por direção.
static func create_rooms() -> Dictionary:
	return {
		"S01": {"coord":Vector2i(0,0), "safe":true, "links":{"N":"S02","NE":"S03","L":"S04","S":"S05","SO":"S06"}},
		"S02": {"coord":Vector2i(0,-1), "safe":true, "links":{"S":"S01"}},
		"S03": {"coord":Vector2i(1,-1), "safe":true, "links":{"SO":"S01"}},
		"S04": {"coord":Vector2i(1,0), "safe":true, "links":{"O":"S01"}},
		"S05": {"coord":Vector2i(0,1), "safe":true, "links":{"N":"S01"}},
		"S06": {"coord":Vector2i(-1,1), "safe":true, "links":{"NE":"S01"}}
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
