extends Control

@onready var panel: InventoryPanel = $InventoryPanel

var _bound_inventory: Inventory
var _restore_visibility_after_chest: bool = false

func _ready() -> void:
	visible = false
	panel.exit_pressed.connect(hide)

func connect_inventory(inventory: Inventory) -> void:
	_bound_inventory = inventory
	panel.bind(inventory)

func suspend_for_chest_transfer() -> void:
	_restore_visibility_after_chest = visible
	panel.unbind()
	hide()

func resume_after_chest_transfer() -> void:
	if _bound_inventory != null:
		panel.bind(_bound_inventory)
	if _restore_visibility_after_chest:
		show_panel()
	_restore_visibility_after_chest = false

func toggle() -> void:
	visible = not visible
	if visible:
		panel.refresh_all()

func show_panel() -> void:
	visible = true
	panel.refresh_all()

func hide_panel() -> void:
	hide()
