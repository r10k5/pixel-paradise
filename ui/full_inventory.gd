extends Control

@onready var inventory_grid: GridContainer = $InventoryContainer/InventoryGrid
@onready var exit_button: Button = $ExitButtonContainer/ExitButton

# Подключаем сигнал нажатия кнопки выхода
func _ready():
	exit_button.pressed.connect(_on_exit_button_pressed)

# Обработчик нажатия кнопки выхода
func _on_exit_button_pressed():
	hide()

# Метод для добавления предмета в инвентарь
func add_item(item: BaseEntity):
	var inventory_cell_scene = preload("res://ui/inventory_cell.tscn")
	var cell_instance = inventory_cell_scene.instantiate() as InventoryCell
	cell_instance.item_texture = item.texture
	cell_instance.item_name = item.id
	cell_instance.item_count = 1
	cell_instance.tooltip_text = item.title
	inventory_grid.add_child(cell_instance)
	
# Метод для отображения полного инвентаря
func show_inventory():
	self.visible = true

# Метод для скрытия полного инвентаря
func hide_inventory():
	self.visible = false
