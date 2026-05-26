extends CanvasLayer

const HOTBAR_SLOTS := 7

@export var inventory_cell_scene: PackedScene
@onready var container: HBoxContainer = $HBoxContainer

var _inventory: Inventory
var _hotbar_cells: Array[InventoryCell] = []

func setup(inventory: Inventory) -> void:
	_inventory = inventory
	for child in container.get_children():
		child.queue_free()
	_hotbar_cells.clear()

	for slot in range(HOTBAR_SLOTS):
		var cell := inventory_cell_scene.instantiate() as InventoryCell
		cell.inventory_item = inventory.get_item(slot)
		container.add_child(cell)
		_hotbar_cells.append(cell)

	if not inventory.item_add.is_connected(_on_item_add):
		inventory.item_add.connect(_on_item_add)
	if not inventory.item_drop.is_connected(_on_item_drop):
		inventory.item_drop.connect(_on_item_drop)

func _on_item_add(item: InventoryItem) -> void:
	_refresh_slot(item.id)

func _on_item_drop(_item: BaseEntity, _count: int) -> void:
	for slot in range(HOTBAR_SLOTS):
		_refresh_slot(slot)

func _refresh_slot(slot: int) -> void:
	if slot < 0 or slot >= _hotbar_cells.size():
		return
	_hotbar_cells[slot].replace(_inventory.get_item(slot))
