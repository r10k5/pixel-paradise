class_name InventoryComponent
extends Node

@export var max_slots: int = 50
@export var max_weight: float = 100.0

signal item_drop(item: BaseEntity, count: int)
signal item_add(item: InventoryItem)
signal contents_changed
signal weight_changed(current_weight: float, max_weight_limit: float)

var _items: Dictionary = {}
var _item_id_index_map: Dictionary = {}


func _ready() -> void:
	_init_slots()


func _init_slots() -> void:
	_items.clear()
	_item_id_index_map.clear()
	for i in range(max_slots):
		var slot := InventoryItem.new()
		slot.id = i
		_items[i] = slot
	_emit_weight()


func _is_valid_id(id: int) -> bool:
	return id in _items


func get_item(id: int) -> InventoryItem:
	if _is_valid_id(id):
		return _items[id]
	return null


func get_items() -> Array:
	return _items.values()


func get_total_weight() -> float:
	var total := 0.0
	for slot_id in _items:
		var inventory_item: InventoryItem = _items[slot_id]
		if inventory_item.is_empty():
			continue
		total += inventory_item.item.item_weight * float(inventory_item.count)
	return total


func can_fit(item: BaseEntity, count: int = 1, exclude_slot_id: int = -1) -> bool:
	if item == null or count <= 0:
		return false
	var current_weight := get_total_weight()
	if exclude_slot_id >= 0 and _is_valid_id(exclude_slot_id):
		var excluded: InventoryItem = _items[exclude_slot_id]
		if not excluded.is_empty():
			current_weight -= excluded.item.item_weight * float(excluded.count)
	var added_weight := item.item_weight * float(count)
	if current_weight + added_weight > max_weight + 0.0001:
		return false
	var remaining := count
	if item.id in _item_id_index_map:
		var slot_id: int = _item_id_index_map[item.id]
		var slot_item: InventoryItem = _items[slot_id]
		var space := item.stack_size - slot_item.count
		remaining -= maxi(0, space)
	if remaining <= 0:
		return true
	for slot_item in _items.values():
		if slot_item.is_empty():
			var put := mini(remaining, item.stack_size)
			remaining -= put
			if remaining <= 0:
				return true
	return remaining <= 0


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
	_emit_weight()


func _emit_weight() -> void:
	weight_changed.emit(get_total_weight(), max_weight)


func _clear_slot(slot_id: int) -> void:
	_items[slot_id].item = null
	_items[slot_id].count = 1


func _set_slot(slot_id: int, item: BaseEntity, count: int) -> void:
	_items[slot_id].item = item
	_items[slot_id].count = count


func _stack_limit(item: BaseEntity) -> int:
	if item == null:
		return 99
	return maxi(1, item.stack_size)


func add_item_by_id(item_id: String, count: int = 1) -> bool:
	var entity := ItemFactory.create(item_id)
	if entity == null:
		return false
	return add_item_stack(entity, count)


func add_item_stack(item: BaseEntity, count: int) -> bool:
	if item == null or count <= 0:
		return false
	if not can_fit(item, count):
		return false
	var remaining := count
	if item.id in _item_id_index_map:
		var index: int = _item_id_index_map[item.id]
		var slot_item: InventoryItem = _items[index]
		var space := _stack_limit(item) - slot_item.count
		if space > 0:
			var add := mini(remaining, space)
			slot_item.count += add
			remaining -= add
			_rebuild_id_map()
			_notify_slot(index)
	if remaining <= 0:
		return true
	for slot_item in _items.values():
		if remaining <= 0:
			break
		if not slot_item.is_empty():
			continue
		var put := mini(remaining, _stack_limit(item))
		_set_slot(slot_item.id, item, put)
		remaining -= put
		_rebuild_id_map()
		_notify_slot(slot_item.id)
	return remaining <= 0


func add_item(item: BaseEntity) -> bool:
	return add_item_stack(item, 1)


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


func remove_item(id: int) -> bool:
	if not _is_valid_id(id):
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
	from_inventory: InventoryComponent,
	from_id: int,
	to_inventory: InventoryComponent,
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
		var exclude_slot := from_id if from_inventory == to_inventory else -1
		if not to_inventory.can_fit(source_item.item, source_item.count, exclude_slot):
			return false
		to_inventory._set_slot(to_id, source_item.item, source_item.count)
		from_inventory._clear_slot(from_id)
	elif source_item.item.id == target_item.item.id:
		var limit := to_inventory._stack_limit(source_item.item)
		var space := limit - target_item.count
		if space <= 0:
			var temp_item := source_item.item
			var temp_count := source_item.count
			from_inventory._set_slot(from_id, target_item.item, target_item.count)
			to_inventory._set_slot(to_id, temp_item, temp_count)
		else:
			var move_count := mini(space, source_item.count)
			target_item.count += move_count
			if source_item.count - move_count <= 0:
				from_inventory._clear_slot(from_id)
			else:
				source_item.count -= move_count
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
	if not _is_valid_id(id):
		return false

	var inventory_item: InventoryItem = _items[id]
	var inventory_count := inventory_item.count
	var remaining_count := inventory_count - count

	if remaining_count <= 0:
		var item := inventory_item.item
		_clear_slot(id)
		_rebuild_id_map()
		item_drop.emit(item, inventory_count)
		_notify_slot(id)
		return true

	_items[id].count = remaining_count
	item_drop.emit(inventory_item.item, count)
	_notify_slot(id)
	return true


func to_save_data() -> Array:
	var slots: Array = []
	for slot_id in _items:
		var inventory_item: InventoryItem = _items[slot_id]
		if inventory_item.is_empty():
			continue
		slots.append({
			"id": slot_id,
			"item_id": str(inventory_item.item.id),
			"count": inventory_item.count,
		})
	return slots


func load_from_save_data(slots: Array) -> void:
	_init_slots()
	for entry in slots:
		if not entry is Dictionary:
			continue
		var slot_id := int(entry.get("id", -1))
		var item_id: String = str(entry.get("item_id", ""))
		var count := int(entry.get("count", 1))
		if slot_id < 0 or slot_id >= max_slots or item_id.is_empty():
			continue
		var entity := ItemFactory.create(item_id)
		if entity == null:
			continue
		_set_slot(slot_id, entity, count)
	_rebuild_id_map()
	contents_changed.emit()
	for slot_id in _items:
		_notify_slot(slot_id)
