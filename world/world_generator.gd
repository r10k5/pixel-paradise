extends Node

signal world_generated(world_map: WorldMap)
signal chunk_generated(chunk: Vector2i)

const TILE_SIZE := 16
const MAP_SCALE := 1.5
const SCATTER_NEAR_PATH_CHANCE := 0.08

@export var generation_settings: WorldGenerationSettings
@export var active_chunk_radius: int = 4
@export var chunk_size: int = 32
@export var map_seed: int = 0

var world_map: WorldMap
var _world_seed: int = 0
var _generated_chunks: Dictionary = {}
var _decoration_generator: DecorationGenerator
var _placed_decorations: Dictionary = {}

@onready var grass_tilemap: TileMap = $"../TileMap"
@onready var water_tilemap: TileMap = $"../WaterGenerator/TileMap"
@onready var player: Node2D = $"../Entities/Actors/Player"

func _ready() -> void:
	if generation_settings == null:
		generation_settings = WorldGenerationSettings.new()
	call_deferred("generate_world")

func generate_world() -> void:
	_world_seed = map_seed if map_seed != 0 else generation_settings.seed
	if _world_seed == 0:
		_world_seed = randi()
	generation_settings.seed = _world_seed
	generation_settings.chunk_size = chunk_size

	world_map = WorldMap.new()
	world_map.generate(0, 0, _world_seed, generation_settings)

	_decoration_generator = DecorationGenerator.new(
		_world_seed,
		generation_settings.global_decoration_multiplier
	)
	_generated_chunks.clear()
	_placed_decorations.clear()
	grass_tilemap.clear()
	water_tilemap.clear()
	world_generated.emit(world_map)
	_ensure_chunks_around_player()

func get_map_seed() -> int:
	return _world_seed

func uses_biome_decorations() -> bool:
	return generation_settings.enable_biomes and generation_settings.enable_decorations

func get_placed_decorations(chunk: Vector2i) -> Array:
	var ck := ChunkEntities.world_chunk_key(chunk)
	if _placed_decorations.has(ck):
		return _placed_decorations[ck]
	return []

func force_refresh_chunks_around_player() -> void:
	_ensure_chunks_around_player()

func _process(_delta: float) -> void:
	_ensure_chunks_around_player()

func get_player_spawn() -> Vector2:
	return _tile_to_world(world_map.spawn_tile)

func regenerate() -> void:
	generate_world()

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return grass_tilemap.local_to_map(grass_tilemap.to_local(world_pos))

func _tile_to_world(tile: Vector2i) -> Vector2:
	return grass_tilemap.to_global(grass_tilemap.map_to_local(tile))

func _tile_to_chunk(tile: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(tile.x) / float(chunk_size)),
		floori(float(tile.y) / float(chunk_size))
	)

func _chunk_dist_sq(a: Vector2i, b: Vector2i) -> int:
	var dx := a.x - b.x
	var dy := a.y - b.y
	return dx * dx + dy * dy

func _chunk_half_extents() -> Vector2i:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	var half := Vector2(400, 225)
	if cam != null:
		var vp := get_viewport().get_visible_rect().size
		half = vp * 0.5 / cam.zoom
	var cell := Vector2(grass_tilemap.tile_set.tile_size) * grass_tilemap.scale
	var tiles_half := Vector2(ceil(half.x / cell.x), ceil(half.y / cell.y))
	return Vector2i(
		int(ceil(tiles_half.x / float(chunk_size))) + active_chunk_radius,
		int(ceil(tiles_half.y / float(chunk_size))) + active_chunk_radius
	)

func get_debug_chunk_info() -> String:
	if player == null or world_map == null:
		return ""
	var center := _tile_to_chunk(_world_to_tile(player.global_position))
	var ext := _chunk_half_extents()
	var chunk_line := "Ch %d,%d ±%d,%d" % [center.x, center.y, ext.x, ext.y]
	if not generation_settings.enable_biomes:
		return chunk_line
	return "%s | %s" % [chunk_line, get_debug_biome_info(_world_to_tile(player.global_position))]

func get_debug_biome_info(tile: Vector2i) -> String:
	if world_map == null or not generation_settings.enable_biomes:
		return ""
	var biome := world_map.get_biome(tile)
	if biome == null:
		return ""
	var height := world_map.height_at(tile)
	var moisture := world_map.moisture_at(tile)
	var temp := world_map.temperature_at(tile)
	return "%s H:%.2f M:%.2f T:%.2f" % [biome.display_name, height, moisture, temp]

func _ensure_chunks_around_player() -> void:
	if player == null or world_map == null:
		return
	var center_chunk := _tile_to_chunk(_world_to_tile(player.global_position))
	var ext := _chunk_half_extents()
	var pending: Array[Vector2i] = []
	for cy in range(center_chunk.y - ext.y, center_chunk.y + ext.y + 1):
		for cx in range(center_chunk.x - ext.x, center_chunk.x + ext.x + 1):
			var chunk := Vector2i(cx, cy)
			var chunk_ck := ChunkEntities.world_chunk_key(chunk)
			if _generated_chunks.has(chunk_ck):
				continue
			pending.append(chunk)
	pending.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _chunk_dist_sq(a, center_chunk) < _chunk_dist_sq(b, center_chunk)
	)
	for chunk in pending:
		var chunk_ck := ChunkEntities.world_chunk_key(chunk)
		_generate_chunk(chunk)
		_generated_chunks[chunk_ck] = true
		chunk_generated.emit(chunk)

func _generate_chunk(chunk: Vector2i) -> void:
	var source_id := 0
	var start_x := chunk.x * chunk_size
	var start_y := chunk.y * chunk_size
	for y in range(start_y, start_y + chunk_size):
		for x in range(start_x, start_x + chunk_size):
			_paint_ground_tile(Vector2i(x, y), source_id)
	for y in range(start_y, start_y + chunk_size):
		for x in range(start_x, start_x + chunk_size):
			_paint_water_tile(Vector2i(x, y), source_id)
	if uses_biome_decorations():
		_generate_decorations(chunk)

func _generate_decorations(chunk: Vector2i) -> void:
	var start_x := chunk.x * chunk_size
	var start_y := chunk.y * chunk_size
	var chunk_ck := ChunkEntities.world_chunk_key(chunk)
	var decorations: Array = []
	var used_tiles: Dictionary = {}
	var spacing := generation_settings.decoration_spacing_tiles
	var margin := spacing

	for y in range(start_y - margin, start_y + chunk_size + margin):
		for x in range(start_x - margin, start_x + chunk_size + margin):
			var tile := Vector2i(x, y)
			var biome := world_map.get_biome(tile)
			if biome == null:
				continue
			var decor := _decoration_generator.should_place_decoration(
				tile, biome, world_map, used_tiles
			)
			if decor.is_empty():
				continue
			var block_spacing := DecorationGenerator.spacing_for_biome(biome, spacing)
			DecorationGenerator.mark_blocked(used_tiles, tile, block_spacing)
			var in_chunk := (
				x >= start_x and x < start_x + chunk_size
				and y >= start_y and y < start_y + chunk_size
			)
			if in_chunk:
				decorations.append({"tile": tile, "data": decor})

	if not decorations.is_empty():
		_placed_decorations[chunk_ck] = decorations

func _paint_ground_tile(tile: Vector2i, source_id: int) -> void:
	var atlas: Vector2i = world_map.get_grass_atlas(tile)
	grass_tilemap.set_cell(0, tile, source_id, atlas, 0)
	if world_map.is_path(tile):
		var style: int = world_map.get_path_style(tile)
		var path_atlas: Vector2i = PathAutotile.resolve(tile, world_map, style)
		grass_tilemap.set_cell(0, tile, source_id, path_atlas, 0)
	elif _should_scatter_stone(tile):
		var stone_roll: int = absi(tile.x * 95123841 ^ tile.y * 72545931 ^ _world_seed) % 1000
		var stone_atlas: Vector2i = PathAutotile.SCATTER_STONE[
			stone_roll % PathAutotile.SCATTER_STONE.size()
		]
		grass_tilemap.set_cell(0, tile, source_id, stone_atlas, 0)

func _should_scatter_stone(tile: Vector2i) -> bool:
	if not world_map.is_grass(tile):
		return false
	if not _is_near_path(tile):
		return false
	var stone_roll: int = absi(tile.x * 95123841 ^ tile.y * 72545931 ^ _world_seed) % 1000
	return stone_roll < int(SCATTER_NEAR_PATH_CHANCE * 1000.0)

func _is_near_path(tile: Vector2i) -> bool:
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if world_map.is_path(tile + offset):
			return true
	return false

func _paint_water_tile(tile: Vector2i, source_id: int) -> void:
	if not world_map.is_water(tile):
		return
	var tile_type = WaterTiles.get_tile_from_world_map(world_map, tile)
	if tile_type == null:
		return
	var atlas: Vector2i = WaterTiles.tile_type_to_atlas(tile_type)
	water_tilemap.set_cell(0, tile, source_id, atlas)
