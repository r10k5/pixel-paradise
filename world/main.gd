extends Node2D

const TREE = preload("res://statics/tree/tree.tscn")
const KUST = preload("res://statics/tree/kust.tscn")
const STONE = preload("res://statics/stone/stone.tscn")
const MUSHROOM = preload("res://statics/pick-up-items/mushroom.tscn")
const FOREST_BERRY = preload("res://statics/pick-up-items/forest_berry.tscn")
const SHADOW_GRASS = preload("res://statics/pick-up-items/shadow_grass.tscn")
const OAK_ROOT = preload("res://statics/pick-up-items/oak_root.tscn")
const ELF_TEAR = preload("res://statics/pick-up-items/elf_tear.tscn")
const BOMB_SCENE = preload("res://statics/bomb/bomb.tscn")
const BOMB_ITEM_SCENE = preload("res://statics/bomb/bomb_item.tscn")
const AXE_ITEM_SCENE = preload("res://statics/tools/axe_base.tscn")
const PICKAXE_ITEM_SCENE = preload("res://statics/tools/pickaxe_base.tscn")
const CHEST_SCENE = preload("res://statics/chest/chest.tscn")
const BOMB_ITEM_ID := "item:bomb"
const MAIN_MENU_SCENE := "res://world/main_menu.tscn"

const TILE_SIZE := 16
const MAP_SCALE := 1.5

@onready var player: Player = $Entities/Actors/Player
@onready var actors: Node2D = $Entities/Actors
@onready var hp_bar = $UI/HP
@onready var droped_items = $Entities/DropItems
@onready var inventory = $UI/Inventory
@onready var full_inventory: Control = $UI/FullInventory
@onready var chest_transfer_ui: Control = $UI/ChestTransferUI
@onready var chests_container: Node2D = $Entities/Chests
@onready var grass_tilemap: TileMap = $TileMap
@onready var world_generator: WorldGenerator = $WorldGenerator
@onready var seed_label: Label = $UI/WorldSeedLabel
@onready var fps_label: Label = $UI/FpsLabel
@onready var day_night: Node2D = $DayNight
@onready var multiverse_manager: Node = $MultiverseManager
@onready var resource_respawn: ResourceRespawnManager = $ResourceRespawnManager

var world_map: WorldMap
var _flora_spawned: Dictionary = {}
var _destroyed_tiles: Dictionary = {}

const MIN_DISTANCE_FROM_WATER_TILES := 1

@export var debug_start_bombs: int = 3

var _player_dying: bool = false

@onready var bombs: Node2D = $Entities/Bombs
@onready var screen_fade: ColorRect = $UI/ScreenFade

func _input(event: InputEvent) -> void:
	if _player_dying or player.is_dead:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			player.scroll_hotbar(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			player.scroll_hotbar(1)
	if event.is_action_pressed("inventory"):
		if chest_transfer_ui.is_open():
			return
		full_inventory.toggle()
	if event.is_action_pressed("interact"):
		if chest_transfer_ui.is_open():
			chest_transfer_ui.close()
		else:
			_try_interact_chest()
	if event.is_action_pressed("bomb"):
		_try_place_bomb()

func _ready() -> void:
	_reset_destroyed_tiles()
	resource_respawn.setup(
		self,
		_is_destroyed,
		_unmark_destroyed,
		_respawn_resource_at_tile
	)
	player.health_changed.connect(on_health_changed)
	inventory.setup(player.inventory, player)
	full_inventory.connect_inventory(player.inventory)
	chest_transfer_ui.closed.connect(_on_chest_transfer_closed)
	InventoryPersistence.load(player.inventory, PlayerProfile.player_id)
	_give_starting_tools()
	_give_debug_bombs()
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
		call_deferred("_spawn_nearby_chests")
		return
	player.global_position = world_generator.get_player_spawn()
	if world_generator.has_method("clamp_player_to_world_bounds"):
		world_generator.clamp_player_to_world_bounds()
	_clear_entities()
	_reset_destroyed_tiles()
	_update_seed_label()
	world_generator.force_refresh_chunks_around_player()
	call_deferred("_spawn_nearby_chests")


func prepare_cell_load(_from_cache: bool) -> void:
	_clear_entities()
	_flora_spawned.clear()


func export_cell_state() -> Dictionary:
	return {
		"destroyed_tiles": WorldCellState.copy_destroyed_tiles(_destroyed_tiles),
		"flora_spawned": _flora_spawned.duplicate(true),
		"respawn_timers": resource_respawn.export_timers(),
	}


func import_cell_state(state: WorldCellState) -> void:
	_destroyed_tiles = WorldCellState.copy_destroyed_tiles(state.destroyed_tiles)
	resource_respawn.import_timers(state.respawn_timers)


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

func _give_starting_tools() -> void:
	var axe := AXE_ITEM_SCENE.instantiate() as BaseEntity
	var pickaxe := PICKAXE_ITEM_SCENE.instantiate() as BaseEntity
	player.inventory.add_item(axe)
	player.inventory.add_item(pickaxe)

func _give_debug_bombs() -> void:
	if debug_start_bombs <= 0:
		return
	for _i in debug_start_bombs:
		var item := BOMB_ITEM_SCENE.instantiate() as BaseEntity
		if not player.inventory.add_item(item):
			break

func _try_place_bomb() -> void:
	if _player_dying or player.is_dead:
		return
	if not player.inventory.consume_one_by_item_id(BOMB_ITEM_ID):
		return
	var bomb := BOMB_SCENE.instantiate()
	var offset := Vector2(-40.0, 0.0) if player.facing_left else Vector2(40.0, 0.0)
	bombs.add_child(bomb)
	bomb.global_position = player.global_position + offset

func on_player_died() -> void:
	if _player_dying:
		return
	_player_dying = true
	InventoryPersistence.save(player.inventory, PlayerProfile.player_id)
	if screen_fade != null:
		await screen_fade.await_fade_out()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _spawn_placements(chunk: Vector2i, placements: Dictionary) -> void:
	var entity_ids := [
		ChunkEntities.TREE_ID,
		ChunkEntities.KUST_ID,
		ChunkEntities.MUSHROOM_ID,
		ChunkEntities.FOREST_BERRY_ID,
		ChunkEntities.SHADOW_GRASS_ID,
		ChunkEntities.OAK_ROOT_ID,
		ChunkEntities.ELF_TEAR_ID,
	]
	for entity_id in entity_ids:
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
		ChunkEntities.FOREST_BERRY_ID:
			return FOREST_BERRY
		ChunkEntities.SHADOW_GRASS_ID:
			return SHADOW_GRASS
		ChunkEntities.OAK_ROOT_ID:
			return OAK_ROOT
		ChunkEntities.ELF_TEAR_ID:
			return ELF_TEAR
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
				_register_world_pickup(item as BaseEntity)
				droped_items.add_child(item)
		)
	var parent: Node = world_generator.get_chunk_entities_parent(chunk)
	parent.add_child(node)
	node.global_position = world_pos

	if node is ResourceNode:
		var resource := node as ResourceNode
		resource.set_spawn_tile(tile)
		resource.harvested.connect(_on_resource_harvested.bind(entity_id, tile))

	return node

func _on_entity_death(entity_id: String, tile: Vector2i) -> void:
	_mark_destroyed(entity_id, tile)

func _on_entity_picked_up(_entity: BaseEntity, entity_id: String, tile: Vector2i) -> void:
	_mark_destroyed(entity_id, tile)

func _reset_destroyed_tiles() -> void:
	_destroyed_tiles = WorldCellState._default_destroyed_tiles()

func _mark_destroyed(entity_id: String, tile: Vector2i) -> void:
	if not _destroyed_tiles.has(entity_id):
		_destroyed_tiles[entity_id] = {}
	_destroyed_tiles[entity_id][ChunkEntities.tile_key(tile)] = true

func _is_destroyed(entity_id: String, tile: Vector2i) -> bool:
	if not _destroyed_tiles.has(entity_id):
		return false
	return _destroyed_tiles[entity_id].has(ChunkEntities.tile_key(tile))


func _unmark_destroyed(entity_id: String, tile: Vector2i) -> void:
	if not _destroyed_tiles.has(entity_id):
		return
	_destroyed_tiles[entity_id].erase(ChunkEntities.tile_key(tile))


func _on_resource_harvested(
	resource_node: ResourceNode,
	entity_id: String,
	tile: Vector2i
) -> void:
	_mark_destroyed(entity_id, tile)
	var item_id := resource_node.item_id
	var respawn_seconds := resource_node.respawn_seconds
	resource_respawn.schedule(entity_id, tile, respawn_seconds)
	if item_id.is_empty():
		return
	player.inventory.add_item_by_id(item_id)


func _respawn_resource_at_tile(entity_id: String, tile: Vector2i) -> void:
	if world_map == null or _is_destroyed(entity_id, tile):
		return
	var scene := _scene_for_entity(entity_id)
	if scene == null:
		return
	var chunk_size := world_generator.chunk_size
	var chunk := Vector2i(
		int(floor(float(tile.x) / float(chunk_size))),
		int(floor(float(tile.y) / float(chunk_size)))
	)
	_spawn_entity(entity_id, scene, tile, chunk)


func _register_world_pickup(item: BaseEntity) -> void:
	if item == null:
		return
	if not item.pick_up.is_connected(on_item_pick_up):
		item.pick_up.connect(on_item_pick_up)


func _on_item_pick_up(item: BaseEntity) -> void:
	if not is_instance_valid(item):
		return
	var item_id := str(item.id)
	if item_id.is_empty():
		return
	if player.inventory.add_item_by_id(item_id):
		item.queue_free()


func on_item_pick_up(item: BaseEntity) -> void:
	call_deferred("_on_item_pick_up", item)

func _spawn_nearby_chests() -> void:
	if not is_instance_valid(player):
		return
	for child in chests_container.get_children():
		if child is Timer:
			continue
		child.queue_free()

	var offsets := [Vector2(80, 0), Vector2(-80, 32)]
	for i in range(offsets.size()):
		var chest := CHEST_SCENE.instantiate()
		chests_container.add_child(chest)
		chest.global_position = player.global_position + offsets[i]
		chest.storage_opened.connect(_on_chest_storage_opened)

func _on_chest_storage_opened(chest: Chest) -> void:
	if chest_transfer_ui.is_open():
		chest_transfer_ui.close()
	full_inventory.suspend_for_chest_transfer()
	chest_transfer_ui.open(chest, player.inventory)

func _on_chest_transfer_closed() -> void:
	full_inventory.resume_after_chest_transfer()

func _try_interact_chest() -> void:
	var chest := _find_interactable_chest()
	if chest != null:
		chest.interact()

func _find_interactable_chest() -> Chest:
	var closest: Chest = null
	var closest_dist := INF
	for child in chests_container.get_children():
		if not child is Chest:
			continue
		var chest := child as Chest
		if not chest.can_interact or not chest.is_player_in_range():
			continue
		var dist := chest.global_position.distance_squared_to(player.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = chest
	return closest
