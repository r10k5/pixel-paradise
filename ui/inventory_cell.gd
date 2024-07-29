extends Control

@export var item_texture: Texture
@export var item_name: String = ""
@export var item_count: int = 0

func _ready():
	$TextureRect.texture = item_texture
	$ItemName.text = item_name
	$ItemCount.text = str(item_count)

func increase_count(amount: int):
	item_count += amount
	$ItemCount.text = str(item_count)

