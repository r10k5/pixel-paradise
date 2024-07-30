# InventoryManager.gd
extends CanvasLayer

@export var inventory_cell_scene: PackedScene
@onready var container: HBoxContainer = $HBoxContainer

#var inventory_content: Dictionary = {}
#
#func add_item(item_id: String, item_name: String, item_texture: Texture): 
	#if item_id in inventory_content:
		#inventory_content[item_id].count += 1
	#else:
		#inventory_content[item_id] = {
			#"id": item_id,
			#"name": item_name,
			#"count": 1,
			#"texture": item_texture,
		#} 
		
func _ready():
	# Начальная настройка, если необходимо
	pass

func add_item_to_inventory(item: BaseEntity):
	if inventory_cell_scene and container:
		var children = container.get_children()
		
		for child in children:
			if (
					child is InventoryCell and
					"item_name" in child and
					child.get("item_name") == item.id
			):
				(child as InventoryCell).increase_count(1)
				return

		var cell_instance = inventory_cell_scene.instantiate() as InventoryCell
		cell_instance.item_texture = item.texture
		cell_instance.item_name = item.id
		cell_instance.item_count = 1
		cell_instance.tooltip_text = item.title
		container.add_child(cell_instance)
