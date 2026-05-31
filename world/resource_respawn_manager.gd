class_name ResourceRespawnManager
extends Node

## tile_key -> respawn_at_msec
var _pending: Dictionary = {}

var _main: Node2D
var _get_destroyed: Callable
var _unmark_destroyed: Callable
var _respawn_tile: Callable


func setup(
	main: Node2D,
	get_destroyed_fn: Callable,
	unmark_destroyed_fn: Callable,
	respawn_tile_fn: Callable
) -> void:
	_main = main
	_get_destroyed = get_destroyed_fn
	_unmark_destroyed = unmark_destroyed_fn
	_respawn_tile = respawn_tile_fn


func schedule(entity_id: String, tile: Vector2i, respawn_seconds: float) -> void:
	var key := _entry_key(entity_id, tile)
	_pending[key] = Time.get_ticks_msec() + int(respawn_seconds * 1000.0)


func export_timers() -> Dictionary:
	return _pending.duplicate(true)


func import_timers(data: Dictionary) -> void:
	_pending = data.duplicate(true)


func _process(_delta: float) -> void:
	if _pending.is_empty():
		return
	var now := Time.get_ticks_msec()
	var done: Array[String] = []
	for key in _pending.keys():
		if int(_pending[key]) <= now:
			done.append(key)
	for key in done:
		_fire_respawn(key)
		_pending.erase(key)


func _entry_key(entity_id: String, tile: Vector2i) -> String:
	return "%s|%s" % [entity_id, ChunkEntities.tile_key(tile)]


func _fire_respawn(key: String) -> void:
	var parts := key.split("|", false, 1)
	if parts.size() != 2:
		return
	var entity_id: String = parts[0]
	var tile := ChunkEntities.tile_from_key(parts[1])
	if _unmark_destroyed.is_valid():
		_unmark_destroyed.call(entity_id, tile)
	if _respawn_tile.is_valid():
		_respawn_tile.call(entity_id, tile)
