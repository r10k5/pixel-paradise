class_name WorldChunk
extends ScreenCullRegion

var chunk_coords: Vector2i = Vector2i.ZERO
var chunk_size_tiles: int = 32

@onready var biome_terrain: Node2D = $BiomeGrassTileMap
@onready var grass_reference_layer: TileMapLayer = $BiomeGrassTileMap/GrasslandLayer
@onready var water_tilemap: TileMap = $WaterTileMap


func _ready() -> void:
	register_content(biome_terrain)
	register_content(water_tilemap)
	super._ready()


func configure(
	chunk: Vector2i,
	size_tiles: int,
	grass_template_root: Node2D,
	water_template: TileMap
) -> void:
	chunk_coords = chunk
	chunk_size_tiles = size_tiles

	BiomeLayerConfig.apply_template_layers(biome_terrain, grass_template_root)
	water_tilemap.tile_set = water_template.tile_set
	water_tilemap.scale = water_template.scale
	water_tilemap.rendering_quadrant_size = water_template.rendering_quadrant_size

	var tile_px := BiomeLayerConfig.tile_pixel_size(grass_template_root)
	var origin := Vector2(chunk.x * size_tiles, chunk.y * size_tiles) * tile_px
	position = origin
	set_cull_rect(Rect2(Vector2.ZERO, Vector2(size_tiles, size_tiles) * tile_px))


func world_tile_to_local(tile: Vector2i) -> Vector2i:
	var origin := chunk_coords * chunk_size_tiles
	return tile - origin
