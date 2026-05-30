class_name Inventory

const MAX_ITEMS = 30

signal item_drop(item: BaseEntity, count: int)
signal item_add(item: InventoryItem)
signal contents_changed

var _items: Dictionary = {}
var _item_id_index_map: Dictionary = {}

func _init():
	for i in range(MAX_ITEMS):
		_items[i] = InventoryItem.new()
		_items[i].id = i

func _is_valid_id(id: int) -> bool:
	return id in _items

func get_item(id: int) -> InventoryItem:
	if _is_valid_id(id):
		return _items[id]
	return null

func get_items() -> Array:
	return _items.values()

func _rebuild_id_map() -> void:
	_item_id_index_map.clear()
	for slot_id in _items:
		var inventory_item: InventoryItem = _items[slot_id]
		if inventory_item.is_empty():
			continue
		if inventory_item.item.id not in _item_id_index_map:
			_item_id_index_map[inventory_item.item.id] = slot_id

func _notify_slot(slot_id: int) -> void:
	if _is_valid_id(slot_id):
		item_add.emit(_items[slot_id])

func _clear_slot(slot_id: int) -> void:
	_items[slot_id].item = null
	_items[slot_id].count = 1

func _set_slot(slot_id: int, item: BaseEntity, count: int) -> void:
	_items[slot_id].item = item
	_items[slot_id].count = count

func consume_one_by_item_id(item_id: String) -> bool:
	for slot_id in _items:
		var inventory_item: InventoryItem = _items[slot_id]
		if inventory_item.is_empty() or inventory_item.item.id != item_id:
			continue
		if inventory_item.count <= 1:
			_clear_slot(slot_id)
		else:
			inventory_item.count -= 1
		_rebuild_id_map()
		_notify_slot(slot_id)
		return true
	return false

func add_item(item: BaseEntity) -> bool:
	if item.id in _item_id_index_map:
		var index = _item_id_index_map[item.id]
		_items[index].count += 1
		_notify_slot(index)
		return true

	var array_items = _items.values()
	var filtered = array_items.filter(func(inventory_item: InventoryItem): return inventory_item.is_empty())

	if len(filtered) == 0:
		return false

	var empty_item = filtered[0]
	_set_slot(empty_item.id, item, 1)
	_rebuild_id_map()
	_notify_slot(empty_item.id)
	return true

func remove_item(id: int) -> bool:
	if !_is_valid_id(id):
		return false

	if _items[id].item == null:
		return false

	_clear_slot(id)
	_rebuild_id_map()
	_notify_slot(id)
	return true

func swap_items(source_id: int, target_id: int) -> bool:
	return transfer_between(self, source_id, self, target_id)

static func transfer_between(
	from_inventory: Inventory,
	from_id: int,
	to_inventory: Inventory,
	to_id: int
) -> bool:
	if from_inventory == null or to_inventory == null:
		return false
	if not from_inventory._is_valid_id(from_id) or not to_inventory._is_valid_id(to_id):
		return false
	if from_id == to_id and from_inventory == to_inventory:
		return false

	var source_item := from_inventory.get_item(from_id)
	var target_item := to_inventory.get_item(to_id)
	if source_item.is_empty():
		return false

	if target_item.is_empty():
		to_inventory._set_slot(to_id, source_item.item, source_item.count)
		from_inventory._clear_slot(from_id)
	elif source_item.item.id == target_item.item.id:
		target_item.count += source_item.count
		from_inventory._clear_slot(from_id)
	else:
		var temp_item := source_item.item
		var temp_count := source_item.count
		from_inventory._set_slot(from_id, target_item.item, target_item.count)
		to_inventory._set_slot(to_id, temp_item, temp_count)

	from_inventory._rebuild_id_map()
	to_inventory._rebuild_id_map()
	from_inventory._notify_slot(from_id)
	to_inventory._notify_slot(to_id)
	if from_inventory != to_inventory:
		from_inventory.contents_changed.emit()
		to_inventory.contents_changed.emit()
	return true

func drop_item(id: int, count: int) -> bool:
	if !_is_valid_id(id):
		return false

	var inventory_item = _items[id]
	var inventory_count = inventory_item.count
	var remaining_count = inventory_count - count

	if remaining_count <= 0:
		var item = inventory_item.item
		_clear_slot(id)
		_rebuild_id_map()
		item_drop.emit(item, inventory_count)
		_notify_slot(id)
		return true

	_items[id].count = remaining_count
	item_drop.emit(inventory_item.item, count)
	_notify_slot(id)
	return true
