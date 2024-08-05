# InventoryManager.gd
extends CanvasLayer

@export var inventory_cell_scene: PackedScene
@onready var container: HBoxContainer = $HBoxContainer

var player_inventory: Inventory

func _ready():
	# Начальная настройка, если необходимо
	pass

func on_add_item(item: InventoryItem):
	if inventory_cell_scene and container:
		var children = container.get_children()
		
		for child in children:
			if (
					child is InventoryCell and
					(child as InventoryCell).inventory_item.id == item.id
			):
				(child as InventoryCell).replace(item)
				return

		var cell_instance = inventory_cell_scene.instantiate() as InventoryCell
		cell_instance.inventory_item = item
		cell_instance.tooltip_text = item.item.title
		container.add_child(cell_instance)
