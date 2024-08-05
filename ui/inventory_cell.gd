extends Control

class_name InventoryCell

var inventory_item: InventoryItem

@onready var item_count_lable = $ItemCount
@onready var item_texture_node = $TextureRect

func _ready():
	item_texture_node.texture = ImageTexture.new()
	item_count_lable.text = ""
	if inventory_item.item:
		item_texture_node.texture = inventory_item.item.texture
		item_count_lable.text = str(inventory_item.count)
	
func replace(item: InventoryItem):
	inventory_item = item
	if inventory_item.item:
		item_texture_node.texture = inventory_item.item.texture
		item_count_lable.text = str(inventory_item.count)
	else:
		item_texture_node.texture = ImageTexture.new()
		item_count_lable.text = ""

