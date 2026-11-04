extends Node

func _ready():
    # Carrega a cena da caverna
    var scene_res = load("res://scenes/world/environments/fase_caverna.tscn")
    var scene = scene_res.instantiate()
    add_child(scene)

    # Função para imprimir informações de um TileMapLayer especificado
    func print_tileset_info(layer_name: String):
        var tilemap = scene.get_node(layer_name)
        if tilemap == null:
            print("Layer ", layer_name, " não encontrado.")
            return
        var ts = tilemap.tile_set
        print("=== TileSet info for layer: ", layer_name, " ===")
        print("TileSet resource path: ", ts.resource_path)
        var source_count = ts.get_source_count()
        for i in range(source_count):
            var src = ts.get_source(i)
            print("-- Source ", i, " (", src.get_class(), ") --")
            if src is TileSetAtlasSource:
                var tex = src.texture
                print("   Texture path: ", tex.resource_path)
                var tile_ids = src.get_tiles_ids()
                for tile_id in tile_ids:
                    var coords = src.get_tile_atlas_coords(tile_id)
                    var region = src.get_tile_texture_region(tile_id)
                    var size = region.size
                    var offset = region.position
                    print("   Tile ID ", tile_id, " -> atlas coords ", coords, " size ", size, " offset ", offset)
            else:
                print("   Fonte não é AtlasSource, classe: ", src.get_class())

    # Imprime informações para todas as camadas relevantes
    print_tileset_info("Paredes")
    print_tileset_info("Piso")
    print_tileset_info("Portas")
    print_tileset_info("Elementos")
    # Encerra o aplicativo
    get_tree().quit()
