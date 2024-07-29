# InventoryManager.gd
extends CanvasLayer

@export var inventory_cell_scene: PackedScene
@export var container: HBoxContainer

func _ready():
	# Начальная настройка, если необходимо
	pass

func _input(event):
	if event.is_action_pressed("pick_up"):
		add_item_to_inventory()

func add_item_to_inventory():
	if inventory_cell_scene and container:
		var item_texture = preload("res://assets/drop_item/log.png")  # Путь к вашей текстуре
		var item_name = "Log"  # Название предмета
		var item_count = 1  # Количество, которое добавляется

		var found = false

		# Проверяем существование предмета в ячейках
		for cell in container.get_children():
			if cell is Control and cell.get("item_name") == item_name:
				cell.increase_count(item_count)
				found = true
				break

		# Если предмет не найден, добавляем новый
		if not found:
			var cell_instance = inventory_cell_scene.instance() as Control
			cell_instance.item_texture = item_texture
			cell_instance.item_name = item_name
			cell_instance.item_count = item_count
			container.add_child(cell_instance)
