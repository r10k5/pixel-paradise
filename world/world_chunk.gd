class_name WorldChunk
extends ScreenCullRegion

var chunk_coords: Vector2i = Vector2i.ZERO
var chunk_size_tiles: int = 32

@onready var grass_tilemap: TileMap = $GrassTileMap
@onready var water_tilemap: TileMap = $WaterTileMap


func _ready() -> void:
	register_content(grass_tilemap)
	register_content(water_tilemap)
	super._ready()


func configure(
	chunk: Vector2i,
	size_tiles: int,
	grass_template: TileMap,
	water_template: TileMap
) -> void:
	chunk_coords = chunk
	chunk_size_tiles = size_tiles

	grass_tilemap.tile_set = grass_template.tile_set
	grass_tilemap.scale = grass_template.scale
	grass_tilemap.rendering_quadrant_size = grass_template.rendering_quadrant_size
	water_tilemap.tile_set = water_template.tile_set
	water_tilemap.scale = water_template.scale
	water_tilemap.rendering_quadrant_size = water_template.rendering_quadrant_size

	var tile_px := Vector2(grass_template.tile_set.tile_size) * grass_template.scale
	var origin := Vector2(chunk.x * size_tiles, chunk.y * size_tiles) * tile_px
	position = origin
	set_cull_rect(Rect2(Vector2.ZERO, Vector2(size_tiles, size_tiles) * tile_px))


func world_tile_to_local(tile: Vector2i) -> Vector2i:
	var origin := chunk_coords * chunk_size_tiles
	return tile - origin
