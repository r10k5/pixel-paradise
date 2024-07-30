extends Control

class_name InventoryCell

var item_texture: Texture
var item_count: int = 0
var item_name: String = ""

@onready var item_count_lable = $ItemCount
@onready var item_texture_node = $TextureRect

func _ready():
	item_texture_node.texture = item_texture
	item_count_lable.text = str(item_count)

func increase_count(amount: int):
	item_count += amount
	item_count_lable.text = str(item_count)

