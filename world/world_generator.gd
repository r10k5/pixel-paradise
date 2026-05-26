extends Node

signal world_generated(world_map: WorldMap)
signal chunk_generated(chunk: Vector2i)

const TILE_SIZE := 16
const MAP_SCALE := 1.5
const SCATTER_NEAR_PATH_CHANCE := 0.08

## Запас чанков вокруг игрока поверх видимой области.
@export var active_chunk_radius: int = 4
@export var chunk_size: int = 32
@export var map_seed: int = 0

var world_map: WorldMap
var _world_seed: int = 0
var _generated_chunks: Dictionary = {}

@onready var grass_tilemap: TileMap = $"../TileMap"
@onready var water_tilemap: TileMap = $"../WaterGenerator/TileMap"
@onready var player: Node2D = $"../Entities/Actors/Player"

func _ready() -> void:
	call_deferred("generate_world")

func generate_world() -> void:
	_world_seed = map_seed if map_seed != 0 else randi()
	world_map = WorldMap.new()
	world_map.generate(0, 0, _world_seed)
	_generated_chunks.clear()
	grass_tilemap.clear()
	water_tilemap.clear()
	world_generated.emit(world_map)
	_ensure_chunks_around_player()

func get_map_seed() -> int:
	return _world_seed

func force_refresh_chunks_around_player() -> void:
	_ensure_chunks_around_player()

func _process(_delta: float) -> void:
	_ensure_chunks_around_player()

func get_player_spawn() -> Vector2:
	return _tile_to_world(world_map.spawn_tile)

func regenerate() -> void:
	generate_world()

## Позиция в клетках тайлмапа — только через TileMap (учитывает scale 1.5 и т.д.).
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


## Половина стороны квадрата чанков вокруг игрока (по ширине/высоте экрана).
func _chunk_half_extents() -> Vector2i:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	var half := Vector2(400, 225)
	if cam != null:
		var vp := get_viewport().get_visible_rect().size
		half = vp * 0.5 / cam.zoom
	var cell := Vector2(grass_tilemap.tile_set.tile_size) * grass_tilemap.scale
	var tiles_half := Vector2(
		ceil(half.x / cell.x),
		ceil(half.y / cell.y)
	)
	return Vector2i(
		int(ceil(tiles_half.x / float(chunk_size))) + active_chunk_radius,
		int(ceil(tiles_half.y / float(chunk_size))) + active_chunk_radius
	)


func get_debug_chunk_info() -> String:
	if player == null or world_map == null:
		return ""
	var center := _tile_to_chunk(_world_to_tile(player.global_position))
	var ext := _chunk_half_extents()
	return "Ch %d,%d ±%d,%d" % [center.x, center.y, ext.x, ext.y]


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
			var tile := Vector2i(x, y)
			_paint_ground_tile(tile, source_id)
	for y in range(start_y, start_y + chunk_size):
		for x in range(start_x, start_x + chunk_size):
			var tile := Vector2i(x, y)
			_paint_water_tile(tile, source_id)

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
	var water_level := -0.22
	if not world_map.is_water(tile):
		return
	var tile_type = WaterTiles.get_tile_from_world_map(world_map, tile, water_level)
	if tile_type == null:
		return
	var atlas: Vector2i = WaterTiles.tile_type_to_atlas(tile_type)
	water_tilemap.set_cell(0, tile, source_id, atlas)
