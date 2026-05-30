extends Control

signal closed

@onready var chest_panel: InventoryPanel = $HBoxContainer/ChestPanel
@onready var player_panel: InventoryPanel = $HBoxContainer/PlayerPanel
@onready var exit_button: Button = $ExitButtonContainer/ExitButton

var _chest: Chest

func _ready() -> void:
	visible = false
	chest_panel.set_exit_visible(false)
	player_panel.set_exit_visible(false)
	exit_button.pressed.connect(close)

func open(chest: Chest, player_inventory: Inventory) -> void:
	if chest == null or chest.storage == null or player_inventory == null:
		return
	_chest = chest
	chest.can_interact = false
	chest_panel.bind(chest.storage)
	player_panel.bind(player_inventory)
	visible = true
	chest_panel.refresh_all()
	player_panel.refresh_all()

func close() -> void:
	if not visible:
		return
	visible = false
	chest_panel.unbind()
	player_panel.unbind()
	if _chest != null:
		_chest.can_interact = true
		_chest.close_storage()
	_chest = null
	closed.emit()

func is_open() -> bool:
	return visible
