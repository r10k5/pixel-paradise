class_name ChestAuthority
extends RefCounted

enum BulkMode { ALL, SIMILAR }

const MAX_INTERACT_DISTANCE := 80.0


static func request_open(chest: Chest, player: Player) -> bool:
	if chest == null or player == null:
		return false
	if not _is_in_range(chest, player):
		return false
	if chest.state == Chest.ChestState.OPEN:
		return true
	_fill_loot_if_needed(chest, player)
	chest.open_storage()
	return true


static func request_close(chest: Chest, _player: Player) -> void:
	if chest == null:
		return
	chest.close_storage()
	ChestPersistence.save(chest)


static func request_bulk_move(
	from_inv: InventoryComponent,
	to_inv: InventoryComponent,
	mode: BulkMode,
	item_id_filter: String = ""
) -> ChestTransferResult:
	var result := ChestTransferResult.new()
	if from_inv == null or to_inv == null:
		result.message = "Invalid inventory"
		return result
	var filter_id := ""
	if mode == BulkMode.SIMILAR:
		filter_id = item_id_filter
	var dict := from_inv.move_all_matching(to_inv, filter_id)
	result.partial = dict.get("partial", false)
	result.moved_stacks = dict.get("moved_stacks", 0)
	if result.partial:
		result.message = "Не всё поместилось"
	if result.moved_stacks > 0 and chest_from_inventories(from_inv, to_inv):
		_save_chest_if_known(from_inv, to_inv)
	return result


static func request_direct_deposit(
	chest: Chest,
	player_inv: InventoryComponent,
	slot_id: int,
	player: Player
) -> bool:
	if chest == null or player_inv == null or player == null:
		return false
	if not _is_in_range(chest, player):
		return false
	if not player_inv.is_valid_slot(slot_id):
		return false
	var inv_item := player_inv.get_item(slot_id)
	if inv_item.is_empty():
		return false
	var target_slot := chest.storage.find_accepting_slot(inv_item.item, inv_item.count)
	if target_slot < 0:
		return false
	if not InventoryComponent.transfer_between(player_inv, slot_id, chest.storage, target_slot):
		return false
	ChestPersistence.save(chest)
	return true


static func _is_in_range(chest: Chest, player: Player) -> bool:
	if chest == null or player == null:
		return false
	if chest.is_player_in_range():
		return true
	return chest.global_position.distance_to(player.global_position) <= MAX_INTERACT_DISTANCE


static func _fill_loot_if_needed(chest: Chest, _player: Player) -> void:
	if chest.loot_table_id.is_empty() or chest.loot_generated:
		return
	if not _storage_is_empty(chest.storage):
		chest.set_loot_generated(true)
		return
	var biome_type := chest.default_biome
	var main := chest.get_tree().current_scene
	if main != null and main.has_method("get_biome_type_at_position"):
		biome_type = main.get_biome_type_at_position(chest.global_position)
	LootGenerator.fill_chest(chest.storage, chest.loot_table_id, chest.loot_seed, biome_type, chest.loot_difficulty)
	chest.set_loot_generated(true)
	ChestPersistence.save(chest)


static func _storage_is_empty(storage: InventoryComponent) -> bool:
	for slot_item in storage.get_items():
		if not slot_item.is_empty():
			return false
	return true


static func chest_from_inventories(from_inv: InventoryComponent, to_inv: InventoryComponent) -> bool:
	return from_inv.get_parent() is Chest or to_inv.get_parent() is Chest


static func _save_chest_if_known(from_inv: InventoryComponent, to_inv: InventoryComponent) -> void:
	if from_inv.get_parent() is Chest:
		ChestPersistence.save(from_inv.get_parent() as Chest)
	if to_inv.get_parent() is Chest:
		ChestPersistence.save(to_inv.get_parent() as Chest)
