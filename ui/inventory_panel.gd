extends Control

class_name InventoryPanel

signal exit_pressed

@onready var inventory_grid: GridContainer = $InventoryContainer/InventoryGrid
@onready var exit_button_container: PanelContainer = $ExitButtonContainer
@onready var exit_button: Button = $ExitButtonContainer/ExitButton

@onready var inventory_cell_scene = preload("res://ui/inventory_cell.tscn")

var _inventory: InventoryComponent
var _selected_slot_id: int = -1
var _cells: Array[InventoryCell] = []

func _ready() -> void:
	exit_button.pressed.connect(func() -> void:
		exit_pressed.emit()
	)

func set_exit_visible(show_exit: bool) -> void:
	exit_button_container.visible = show_exit

func bind(inventory: InventoryComponent) -> void:
	unbind()
	_inventory = inventory
	_build_grid()
	_connect_inventory(inventory)

func unbind() -> void:
	if _inventory == null:
		return
	_disconnect_inventory(_inventory)
	_inventory = null

func refresh_all() -> void:
	for child in inventory_grid.get_children():
		if child is InventoryCell:
			(child as InventoryCell).refresh()

func get_selected_item_id() -> String:
	if _selected_slot_id < 0 or _inventory == null:
		return ""
	var inv_item := _inventory.get_item(_selected_slot_id)
	if inv_item == null or inv_item.is_empty():
		return ""
	return str(inv_item.item.id)


func _build_grid() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	_cells.clear()
	_selected_slot_id = -1
	if _inventory == null:
		return
	for slot_item in _inventory.get_items():
		var cell := inventory_cell_scene.instantiate() as InventoryCell
		cell.bind(_inventory, slot_item.id)
		cell.cell_pressed.connect(_on_cell_pressed)
		inventory_grid.add_child(cell)
		_cells.append(cell)


func _on_cell_pressed(cell: InventoryCell) -> void:
	_selected_slot_id = cell.slot_id
	for c in _cells:
		c.set_selected(c == cell)

func _connect_inventory(inventory: InventoryComponent) -> void:
	if not inventory.item_add.is_connected(_on_inventory_changed):
		inventory.item_add.connect(_on_inventory_changed)
	if not inventory.item_drop.is_connected(_on_inventory_changed_drop):
		inventory.item_drop.connect(_on_inventory_changed_drop)
	if not inventory.contents_changed.is_connected(_on_contents_changed):
		inventory.contents_changed.connect(_on_contents_changed)

func _disconnect_inventory(inventory: InventoryComponent) -> void:
	if inventory.item_add.is_connected(_on_inventory_changed):
		inventory.item_add.disconnect(_on_inventory_changed)
	if inventory.item_drop.is_connected(_on_inventory_changed_drop):
		inventory.item_drop.disconnect(_on_inventory_changed_drop)
	if inventory.contents_changed.is_connected(_on_contents_changed):
		inventory.contents_changed.disconnect(_on_contents_changed)

func _on_inventory_changed(item: InventoryItem) -> void:
	_refresh_slot(item.id)

func _on_inventory_changed_drop(_item: BaseEntity, _count: int) -> void:
	refresh_all()

func _on_contents_changed() -> void:
	refresh_all()

func _refresh_slot(slot_id: int) -> void:
	for child in inventory_grid.get_children():
		if child is InventoryCell and (child as InventoryCell).slot_id == slot_id:
			(child as InventoryCell).refresh()
			return
