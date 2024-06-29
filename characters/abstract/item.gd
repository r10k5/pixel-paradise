extends Node

enum ItemType {
	AbstractItem,
	Effect,
}

var _item_type = ItemType.AbstractItem
var _item_name = "abstract_item"

func set_item_name(item_name: String):
	_item_name = item_name
	
func get_item_name():
	return _item_name

func map_string_to_item_type(type: String) -> ItemType:
	match type.to_lower():
		"effect":
			return ItemType.Effect
		_:
			return ItemType.AbstractItem

func set_item_type(type: ItemType):
	_item_type = type
	
func get_item_type() -> ItemType:
	return _item_type
	
func is_effect():
	return _item_type == ItemType.Effect
	
func is_abstract_item():
	return _item_type == ItemType.AbstractItem
