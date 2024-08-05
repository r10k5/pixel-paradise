extends Control

@onready var inventory_grid: GridContainer = $InventoryContainer/InventoryGrid
@onready var exit_button: Button = $ExitButtonContainer/ExitButton
	
@onready var inventory_cell_scene = preload("res://ui/inventory_cell.tscn")

# Подключаем сигнал нажатия кнопки выхода
func _ready():
	exit_button.pressed.connect(_on_exit_button_pressed)

func connect_inventory(inventory: Inventory):
	for item in inventory.get_items():
		var cell_instance = inventory_cell_scene.instantiate() as InventoryCell
		cell_instance.inventory_item = item as InventoryItem
		inventory_grid.add_child(cell_instance)
	
	inventory.item_add.connect(on_change_item)
	inventory.item_drop.connect(on_change_item)

# Обработчик нажатия кнопки выхода
func _on_exit_button_pressed():
	hide()

# Метод для отображения подобранной вещи
func on_change_item(item: InventoryItem):
	for child in inventory_grid.get_children():
		if (
				child is InventoryCell and
				(child as InventoryCell).inventory_item.id == item.id
		):
			(child as InventoryCell).replace(item)
			return
	
# Метод для отображения полного инвентаря
func show_inventory():
	self.visible = true

# Метод для скрытия полного инвентаря
func hide_inventory():
	self.visible = false
