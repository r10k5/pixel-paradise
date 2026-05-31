extends CanvasLayer

const HOTBAR_SLOTS := 7

@export var inventory_cell_scene: PackedScene
@onready var container: HBoxContainer = $HBoxContainer

var _inventory: InventoryComponent
var _player: Player
var _hotbar_cells: Array[InventoryCell] = []

func setup(inventory: InventoryComponent, player: Player) -> void:
	_inventory = inventory
	_player = player
	for child in container.get_children():
		child.queue_free()
	_hotbar_cells.clear()

	for slot in range(HOTBAR_SLOTS):
		var cell := inventory_cell_scene.instantiate() as InventoryCell
		cell.bind(inventory, slot)
		container.add_child(cell)
		_hotbar_cells.append(cell)

	if not inventory.item_add.is_connected(_on_item_add):
		inventory.item_add.connect(_on_item_add)
	if not inventory.item_drop.is_connected(_on_item_drop):
		inventory.item_drop.connect(_on_item_drop)
	if not inventory.contents_changed.is_connected(_on_contents_changed):
		inventory.contents_changed.connect(_on_contents_changed)
	if _player and not _player.hotbar_slot_changed.is_connected(_on_hotbar_slot_changed):
		_player.hotbar_slot_changed.connect(_on_hotbar_slot_changed)
	_update_selection_highlight()

func _on_item_add(item: InventoryItem) -> void:
	_refresh_slot(item.id)

func _on_item_drop(_item: BaseEntity, _count: int) -> void:
	for slot in range(HOTBAR_SLOTS):
		_refresh_slot(slot)

func _on_contents_changed() -> void:
	for slot in range(HOTBAR_SLOTS):
		_refresh_slot(slot)

func _refresh_slot(slot: int) -> void:
	if slot < 0 or slot >= _hotbar_cells.size():
		return
	_hotbar_cells[slot].refresh()

func _on_hotbar_slot_changed(_slot: int) -> void:
	_update_selection_highlight()

func _update_selection_highlight() -> void:
	if _player == null:
		return
	for slot in range(_hotbar_cells.size()):
		_hotbar_cells[slot].set_selected(slot == _player.selected_hotbar_slot)
