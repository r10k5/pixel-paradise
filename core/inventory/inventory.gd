class_name Inventory

const MAX_ITEMS = 30

signal item_drop(item: BaseEntity, count: int)
signal item_add(item: InventoryItem)

var _items: Dictionary = {}
var _item_id_index_map: Dictionary = {}

func _init():
	for i in range(MAX_ITEMS):
		_items[i] = InventoryItem.new()
		_items[i].id = i
		
func _is_valid_id(id: int):
	return id in _items
		
func get_item(id: int) -> InventoryItem:
	if _is_valid_id(id):
		return _items[id]
	
	return null
	
func get_items() -> Array:
	return _items.values()
	
func add_item(item: BaseEntity) -> bool:
	if item.id in _item_id_index_map:
		var index = _item_id_index_map[item.id]
		_items[index].count += 1
		
		item_add.emit(_items[index])
		
		return true
	
	var array_items = _items.values()
	var filtered = array_items.filter(func(inventory_item: InventoryItem): return inventory_item.is_empty())
	
	if len(filtered) == 0:
		return false
		
	var empty_item = filtered[0]
	
	_items[empty_item.id].item = item
	_items[empty_item.id].count = 1
	_item_id_index_map[item.id] = empty_item.id
	
	item_add.emit(_items[empty_item.id])
	
	return true

func remove_item(id: int) -> bool:
	if !_is_valid_id(id):
		return false
		
	if _items[id].item == null:
		return false
	
	_item_id_index_map.erase(id)
	
	_items[id] = InventoryItem.new()
	_items[id].id = id
	
	return true

func swap_items(source_id: int, target_id: int) -> bool:
	if !_is_valid_id(target_id) or !_is_valid_id(source_id):
		return false
		
	var temp_item = _items[source_id].item
	var temp_count = _items[source_id].count
	var target_item_id = _items[target_id].item.id
	
	# Меняем элементы местами
	_items[source_id].item = _items[target_id].item
	_items[source_id].count = _items[target_id].count
	_items[target_id].item = temp_item
	_items[target_id].count = temp_count
	
	_item_id_index_map[temp_item.item.id] = target_id
	_item_id_index_map[target_item_id] = source_id
	
	return true
	
func drop_item(id: int, count: int) -> bool:
	if !_is_valid_id(id):
		return false
		
	var inventory_item = _items[id]
	var inventory_count = inventory_item.count
	var remaining_count = inventory_count - count
	
	if remaining_count <= 0:
		var item = inventory_item.item
		
		_items[id].item = null
		_items[id].count = 1
		
		item_drop.emit(item, inventory_count)
		
		return true
	else:
		_items[id].count = remaining_count
		
		item_drop.emit(inventory_item, count)
		
		return true
	
