class_name WorldCellState
extends RefCounted

var grid_pos: Vector2i = Vector2i.ZERO
## Сид всей вселенной (одинаковый для всех ячеек сетки).
var world_seed: int = 0
var spawn_tile: Vector2i = Vector2i.ZERO
var player_tile: Vector2i = Vector2i.ZERO
var destroyed_tiles: Dictionary = {}
var flora_spawned: Dictionary = {}


func _init(
	p_grid_pos: Vector2i = Vector2i.ZERO,
	p_world_seed: int = 0,
	p_spawn_tile: Vector2i = Vector2i.ZERO,
	p_player_tile: Vector2i = Vector2i.ZERO
) -> void:
	grid_pos = p_grid_pos
	world_seed = p_world_seed
	spawn_tile = p_spawn_tile
	player_tile = p_player_tile
	destroyed_tiles = _default_destroyed_tiles()
	flora_spawned = {}


static func _default_destroyed_tiles() -> Dictionary:
	return {
		ChunkEntities.TREE_ID: {},
		ChunkEntities.KUST_ID: {},
		ChunkEntities.MUSHROOM_ID: {},
		ChunkEntities.STONE_ID: {},
	}


static func grid_key(grid_pos: Vector2i) -> String:
	return "%d,%d" % [grid_pos.x, grid_pos.y]


static func grid_from_key(key: String) -> Vector2i:
	var parts: PackedStringArray = key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func duplicate_state() -> WorldCellState:
	var copy := WorldCellState.new(grid_pos, world_seed, spawn_tile, player_tile)
	copy.destroyed_tiles = _deep_copy_destroyed(destroyed_tiles)
	copy.flora_spawned = flora_spawned.duplicate(true)
	return copy


static func copy_destroyed_tiles(source: Dictionary) -> Dictionary:
	return _deep_copy_destroyed(source)


static func _deep_copy_destroyed(source: Dictionary) -> Dictionary:
	var out := _default_destroyed_tiles()
	for entity_id in source.keys():
		if source[entity_id] is Dictionary:
			out[entity_id] = (source[entity_id] as Dictionary).duplicate(true)
	return out


func to_dict() -> Dictionary:
	var destroyed_out: Dictionary = {}
	for entity_id in destroyed_tiles.keys():
		destroyed_out[entity_id] = (destroyed_tiles[entity_id] as Dictionary).duplicate(true)
	return {
		"grid_x": grid_pos.x,
		"grid_y": grid_pos.y,
		"world_seed": world_seed,
		"spawn_x": spawn_tile.x,
		"spawn_y": spawn_tile.y,
		"player_x": player_tile.x,
		"player_y": player_tile.y,
		"destroyed_tiles": destroyed_out,
		"flora_spawned": flora_spawned.duplicate(true),
	}


static func from_dict(data: Dictionary) -> WorldCellState:
	var state := WorldCellState.new(
		Vector2i(int(data.get("grid_x", 0)), int(data.get("grid_y", 0))),
		int(data.get("world_seed", 0)),
		Vector2i(int(data.get("spawn_x", 0)), int(data.get("spawn_y", 0))),
		Vector2i(int(data.get("player_x", 0)), int(data.get("player_y", 0)))
	)
	var destroyed: Variant = data.get("destroyed_tiles", {})
	if destroyed is Dictionary:
		state.destroyed_tiles = _deep_copy_destroyed(destroyed)
	var flora: Variant = data.get("flora_spawned", {})
	if flora is Dictionary:
		state.flora_spawned = (flora as Dictionary).duplicate(true)
	return state
