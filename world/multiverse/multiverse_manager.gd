extends Node

signal cell_loaded(grid_pos: Vector2i, state: WorldCellState)

@export var multiverse_grid_radius: int = 1
@export var transition_margin_tiles: int = 3
@export var fade_duration: float = 0.45
@export var base_seed: int = 0

var _current_grid_pos: Vector2i = Vector2i.ZERO
var _cell_cache: Dictionary = {}
var _transitioning: bool = false
var _pending_entry_edge: Vector2i = Vector2i.ZERO
@onready var world_generator: WorldGenerator = $"../WorldGenerator"
@onready var main: Node2D = $".."
@onready var player: CharacterBody2D = $"../Entities/Actors/Player"
@onready var screen_fade: ColorRect = $"../UI/ScreenFade"


func _ready() -> void:
	if screen_fade != null:
		screen_fade.fade_duration = fade_duration
	if world_generator.has_method("set_multiverse_boundary_check"):
		world_generator.set_multiverse_boundary_check(Callable(self, "_is_boundary_open"))
	call_deferred("_start_multiverse")


func _start_multiverse() -> void:
	if world_generator.has_method("set_auto_generate_on_ready"):
		world_generator.auto_generate_on_ready = false
	_ensure_universe_seed()
	await load_cell(Vector2i.ZERO, Vector2i.ZERO, true)


func get_current_grid_pos() -> Vector2i:
	return _current_grid_pos


func can_transition_to(offset: Vector2i) -> bool:
	var target := _current_grid_pos + offset
	return (
		absi(target.x) <= multiverse_grid_radius
		and absi(target.y) <= multiverse_grid_radius
	)


func _ensure_universe_seed() -> void:
	if base_seed == 0:
		base_seed = randi()


func _physics_process(_delta: float) -> void:
	if _transitioning or world_generator.world_map == null:
		return
	_check_edge_transition()


func _check_edge_transition() -> void:
	var tile := world_generator.world_to_tile(player.global_position)
	var bounds := world_generator.get_world_tile_bounds()
	var margin := transition_margin_tiles
	var edge := Vector2i.ZERO

	if tile.x <= bounds.position.x + margin:
		edge.x = -1
	elif tile.x >= bounds.end.x - 1 - margin:
		edge.x = 1

	if tile.y <= bounds.position.y + margin:
		edge.y = -1
	elif tile.y >= bounds.end.y - 1 - margin:
		edge.y = 1

	if edge == Vector2i.ZERO:
		return
	if not can_transition_to(edge):
		return
	request_transition(edge)


func request_transition(edge: Vector2i) -> void:
	if _transitioning or edge == Vector2i.ZERO:
		return
	if not can_transition_to(edge):
		return
	_transitioning = true
	_run_transition(edge)


func _run_transition(edge: Vector2i) -> void:
	var saved_velocity := player.velocity
	await screen_fade.await_fade_out()
	save_current_cell()
	world_generator.unload_world()
	var target := _current_grid_pos + edge
	_pending_entry_edge = -edge
	await load_cell(target, _pending_entry_edge, false)
	player.velocity = saved_velocity
	await screen_fade.await_fade_in()
	_transitioning = false


func save_current_cell() -> void:
	if world_generator.world_map == null:
		return
	var state := _build_state_from_session(_current_grid_pos)
	state.player_tile = world_generator.world_to_tile(player.global_position)
	_cell_cache[WorldCellState.grid_key(_current_grid_pos)] = state


func _build_state_from_session(grid_pos: Vector2i) -> WorldCellState:
	var state := WorldCellState.new()
	state.grid_pos = grid_pos
	state.world_seed = world_generator.get_map_seed()
	state.spawn_tile = world_generator.world_map.spawn_tile
	state.player_tile = world_generator.world_to_tile(player.global_position)
	if main.has_method("export_cell_state"):
		var exported: Dictionary = main.export_cell_state()
		state.destroyed_tiles = exported.get("destroyed_tiles", state.destroyed_tiles)
		state.flora_spawned = exported.get("flora_spawned", state.flora_spawned)
		var timers: Variant = exported.get("respawn_timers", {})
		if timers is Dictionary:
			state.respawn_timers = (timers as Dictionary).duplicate(true)
	return state


func load_cell(grid_pos: Vector2i, entry_edge: Vector2i, is_initial: bool) -> void:
	_current_grid_pos = grid_pos
	var cache_key := WorldCellState.grid_key(grid_pos)
	var cached: WorldCellState = null
	if _cell_cache.has(cache_key):
		cached = (_cell_cache[cache_key] as WorldCellState).duplicate_state()

	_ensure_universe_seed()

	if main.has_method("prepare_cell_load"):
		main.prepare_cell_load(cached != null)

	world_generator.generate_for_cell(grid_pos, base_seed)

	var state := cached
	if state == null:
		state = WorldCellState.new(
			grid_pos,
			base_seed,
			world_generator.world_map.spawn_tile,
			world_generator.world_map.spawn_tile
		)

	if main.has_method("import_cell_state"):
		main.import_cell_state(state)

	state.world_seed = base_seed

	var spawn_tile := _resolve_spawn_tile(state, entry_edge, is_initial)
	player.global_position = world_generator.tile_to_world(spawn_tile)
	state.player_tile = spawn_tile

	_cell_cache[cache_key] = state.duplicate_state()
	cell_loaded.emit(grid_pos, state)
	world_generator.force_refresh_chunks_around_player()
	if main.has_method("update_multiverse_label"):
		main.update_multiverse_label()


func _resolve_spawn_tile(state: WorldCellState, entry_edge: Vector2i, is_initial: bool) -> Vector2i:
	if is_initial:
		return world_generator.world_map.spawn_tile
	if entry_edge != Vector2i.ZERO:
		return _entry_tile_for_edge(entry_edge)
	if state.player_tile != Vector2i.ZERO:
		return state.player_tile
	return state.spawn_tile


func _entry_tile_for_edge(entry_edge: Vector2i) -> Vector2i:
	var bounds := world_generator.get_world_tile_bounds()
	var margin := transition_margin_tiles
	var tile := Vector2i.ZERO

	if entry_edge.x == 1:
		tile.x = bounds.position.x + margin
	elif entry_edge.x == -1:
		tile.x = bounds.end.x - 1 - margin
	else:
		tile.x = (bounds.position.x + bounds.end.x) >> 1

	if entry_edge.y == 1:
		tile.y = bounds.position.y + margin
	elif entry_edge.y == -1:
		tile.y = bounds.end.y - 1 - margin
	else:
		tile.y = (bounds.position.y + bounds.end.y) >> 1

	return tile


func _is_boundary_open(edge: Vector2i) -> bool:
	if edge == Vector2i.ZERO:
		return false
	return can_transition_to(edge)
