extends Control

class_name InventoryCell

var inventory_item: InventoryItem

@onready var item_count_lable = $ItemCount
@onready var item_texture_node = $TextureRect
@onready var background = $Background

const SELECTED_TINT := Color(1.15, 1.15, 0.75)
const NORMAL_TINT := Color.WHITE

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

func set_selected(selected: bool) -> void:
	if background:
		background.modulate = SELECTED_TINT if selected else NORMAL_TINT

