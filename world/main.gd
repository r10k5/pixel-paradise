extends Node2D

const TREE = preload("res://statics/tree/tree.tscn")
const MUSHROOM = preload("res://statics/mushrooms/mushroom.tscn")
const KUST = preload("res://statics/tree/kust.tscn")
const STONE = preload("res://statics/stone/stone.tscn")

const TILE_SIZE := 16
const MAP_SCALE := 1.5

@onready var player: Player = $Entities/Actors/Player
@onready var actors: Node2D = $Entities/Actors
@onready var hp_bar = $UI/HP
@onready var droped_items = $Entities/DropItems
@onready var inventory = $UI/Inventory
@onready var full_inventory: Control = $UI/FullInventory
@onready var grass_tilemap: TileMap = $TileMap
@onready var world_generator: WorldGenerator = $WorldGenerator
@onready var seed_label: Label = $UI/WorldSeedLabel
@onready var fps_label: Label = $UI/FpsLabel
@onready var day_night: Node2D = $DayNight
@onready var multiverse_manager: Node = $MultiverseManager

var world_map: WorldMap
var _flora_spawned: Dictionary = {}
var _destroyed_tiles: Dictionary = {
	ChunkEntities.TREE_ID: {},
	ChunkEntities.KUST_ID: {},
	ChunkEntities.MUSHROOM_ID: {},
}

const MIN_DISTANCE_FROM_WATER_TILES := 1

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		full_inventory.toggle()

func _ready() -> void:
	player.health_changed.connect(on_health_changed)
	inventory.setup(player.inventory)
	full_inventory.connect_inventory(player.inventory)
	on_health_changed(player.health)
	world_generator.world_generated.connect(_on_world_generated)
	world_generator.chunk_generated.connect(_on_chunk_generated)

func _process(_delta: float) -> void:
	_update_forest_ambience()
	if fps_label and world_generator.has_method("get_debug_chunk_info"):
		fps_label.text = "FPS: %d  %s" % [
			int(Engine.get_frames_per_second()),
			world_generator.get_debug_chunk_info()
		]

func _update_forest_ambience() -> void:
	if day_night == null or not day_night.has_method("set_forest_darkness"):
		return
	if world_map == null or not world_map.settings.enable_biomes:
		day_night.set_forest_darkness(0.0)
		return
	var tile := grass_tilemap.local_to_map(grass_tilemap.to_local(player.global_position))
	var biome := world_map.get_biome(tile)
	var in_forest := biome != null and biome.biome_type == Biome.BiomeType.FOREST
	day_night.set_forest_darkness(1.0 if in_forest else 0.0)

func _on_world_generated(map: WorldMap) -> void:
	world_map = map
	if multiverse_manager != null:
		update_multiverse_label()
		return
	player.global_position = world_generator.get_player_spawn()
	if world_generator.has_method("clamp_player_to_world_bounds"):
		world_generator.clamp_player_to_world_bounds()
	_clear_entities()
	_reset_destroyed_tiles()
	_update_seed_label()
	world_generator.force_refresh_chunks_around_player()


func prepare_cell_load(_from_cache: bool) -> void:
	_clear_entities()
	_flora_spawned.clear()


func export_cell_state() -> Dictionary:
	return {
		"destroyed_tiles": WorldCellState.copy_destroyed_tiles(_destroyed_tiles),
		"flora_spawned": _flora_spawned.duplicate(true),
	}


func import_cell_state(state: WorldCellState) -> void:
	_destroyed_tiles = WorldCellState.copy_destroyed_tiles(state.destroyed_tiles)


func update_multiverse_label() -> void:
	if seed_label == null:
		return
	var grid := Vector2i.ZERO
	var world_seed: int = 0
	if world_generator.has_method("get_map_seed"):
		world_seed = world_generator.get_map_seed()
	if multiverse_manager != null and multiverse_manager.has_method("get_current_grid_pos"):
		grid = multiverse_manager.get_current_grid_pos()
	seed_label.text = "Cell (%d,%d) · Universe seed %d" % [grid.x, grid.y, world_seed]


func _update_seed_label() -> void:
	update_multiverse_label()

func _clear_entities() -> void:
	for node in actors.get_children():
		if node == player:
			continue
		node.queue_free()
	for node in droped_items.get_children():
		node.queue_free()
	_flora_spawned.clear()

func _on_chunk_generated(chunk: Vector2i) -> void:
	call_deferred("_spawn_flora_deferred", chunk)

func _spawn_flora_deferred(chunk: Vector2i) -> void:
	if world_map == null or not is_instance_valid(world_generator):
		return
	var ck := ChunkEntities.world_chunk_key(chunk)
	if _flora_spawned.has(ck):
		return
	_flora_spawned[ck] = true

	if world_generator.uses_biome_decorations():
		_spawn_biome_decorations(chunk)
	else:
		var placements := ChunkEntities.get_placements(
			world_generator.get_map_seed(),
			chunk,
			world_generator.chunk_size,
			world_map
		)
		_spawn_placements(chunk, placements)

func _spawn_biome_decorations(chunk: Vector2i) -> void:
	for entry in world_generator.get_placed_decorations(chunk):
		var tile: Vector2i = entry.tile
		var data: Dictionary = entry.data
		var entity_id: String = data.get("entity_id", "")
		if entity_id.is_empty():
			continue
		if _is_destroyed(entity_id, tile):
			continue
		var scene_path: String = data.get("scene", "")
		if scene_path.is_empty():
			continue
		var packed := load(scene_path) as PackedScene
		if packed == null:
			continue
		_spawn_entity(entity_id, packed, tile, chunk)

func on_health_changed(current_health: int) -> void:
	hp_bar.set_hp(current_health)

func _spawn_placements(chunk: Vector2i, placements: Dictionary) -> void:
	for entity_id in [ChunkEntities.TREE_ID, ChunkEntities.KUST_ID, ChunkEntities.MUSHROOM_ID]:
		var scene: PackedScene = _scene_for_entity(entity_id)
		if scene == null:
			continue
		for tile in placements[entity_id]:
			if _is_near_water(tile):
				continue
			if _is_destroyed(entity_id, tile):
				continue
			_spawn_entity(entity_id, scene, tile, chunk)

func _is_near_water(tile: Vector2i) -> bool:
	var r := MIN_DISTANCE_FROM_WATER_TILES
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if world_map.is_water(tile + Vector2i(dx, dy)):
				return true
	return false

func _scene_for_entity(entity_id: String) -> PackedScene:
	match entity_id:
		ChunkEntities.TREE_ID:
			return TREE
		ChunkEntities.KUST_ID:
			return KUST
		ChunkEntities.MUSHROOM_ID:
			return MUSHROOM
		ChunkEntities.STONE_ID:
			return STONE
	return null

func _spawn_entity(entity_id: String, scene: PackedScene, tile: Vector2i, chunk: Vector2i) -> Node:
	var node := scene.instantiate()
	var world_pos := grass_tilemap.to_global(grass_tilemap.map_to_local(tile))

	if node is BaseEntity:
		node.death.connect(_on_entity_death.bind(entity_id, tile))

	if entity_id == ChunkEntities.TREE_ID:
		var tree := node as BaseEntity
		tree.drop_item.connect(func(item):
			item.global_position = tree.global_position
			if item is BaseEntity:
				(item as BaseEntity).pick_up.connect(on_item_pick_up)
				actors.add_child(item)
		)
	elif entity_id == ChunkEntities.MUSHROOM_ID:
		node.pick_up.connect(on_item_pick_up)
		node.pick_up.connect(_on_entity_picked_up.bind(entity_id, tile))

	var parent: Node = world_generator.get_chunk_entities_parent(chunk)
	parent.add_child(node)
	node.global_position = world_pos
	return node

func _on_entity_death(entity_id: String, tile: Vector2i) -> void:
	_mark_destroyed(entity_id, tile)

func _on_entity_picked_up(_entity: BaseEntity, entity_id: String, tile: Vector2i) -> void:
	_mark_destroyed(entity_id, tile)

func _reset_destroyed_tiles() -> void:
	_destroyed_tiles = {
		ChunkEntities.TREE_ID: {},
		ChunkEntities.KUST_ID: {},
		ChunkEntities.MUSHROOM_ID: {},
		ChunkEntities.STONE_ID: {},
	}

func _mark_destroyed(entity_id: String, tile: Vector2i) -> void:
	if not _destroyed_tiles.has(entity_id):
		_destroyed_tiles[entity_id] = {}
	_destroyed_tiles[entity_id][ChunkEntities.tile_key(tile)] = true

func _is_destroyed(entity_id: String, tile: Vector2i) -> bool:
	if not _destroyed_tiles.has(entity_id):
		return false
	return _destroyed_tiles[entity_id].has(ChunkEntities.tile_key(tile))

func _on_item_pick_up(item: BaseEntity) -> void:
	if not is_instance_valid(item):
		return
	var par: Node = item.get_parent()
	if par == null:
		player.inventory.add_item(item)
		return
	var children: Array = par.get_children()
	if item in children:
		player.inventory.add_item(item)
		par.remove_child(item)

func on_item_pick_up(item: BaseEntity) -> void:
	if player in item.entities_near:
		call_deferred("_on_item_pick_up", item)
