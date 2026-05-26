extends Control

@onready var inventory_grid: GridContainer = $InventoryContainer/InventoryGrid
@onready var exit_button: Button = $ExitButtonContainer/ExitButton

@onready var inventory_cell_scene = preload("res://ui/inventory_cell.tscn")

var _inventory: Inventory

func _ready() -> void:
	visible = false
	exit_button.pressed.connect(hide)

func connect_inventory(inventory: Inventory) -> void:
	_inventory = inventory
	_build_grid()
	inventory.item_add.connect(_on_inventory_changed)
	inventory.item_drop.connect(_on_inventory_changed_drop)

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh_all()

func _build_grid() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	for slot_item in _inventory.get_items():
		var cell := inventory_cell_scene.instantiate() as InventoryCell
		cell.inventory_item = slot_item
		inventory_grid.add_child(cell)

func _refresh_all() -> void:
	var cells := inventory_grid.get_children()
	var items := _inventory.get_items()
	for i in range(mini(cells.size(), items.size())):
		if cells[i] is InventoryCell:
			(cells[i] as InventoryCell).replace(items[i])

func _on_inventory_changed(item: InventoryItem) -> void:
	_refresh_slot(item.id)

func _on_inventory_changed_drop(_item: BaseEntity, _count: int) -> void:
	_refresh_all()

func _refresh_slot(slot_id: int) -> void:
	for child in inventory_grid.get_children():
		if child is InventoryCell and (child as InventoryCell).inventory_item.id == slot_id:
			(child as InventoryCell).replace(_inventory.get_item(slot_id))
			return
