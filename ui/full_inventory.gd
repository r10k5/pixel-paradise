extends Control

@onready var panel: InventoryPanel = $InventoryPanel
@onready var weight_label: Label = $WeightLabel

var _bound_inventory: InventoryComponent
var _restore_visibility_after_chest: bool = false

func _ready() -> void:
	visible = false
	panel.exit_pressed.connect(hide)

func connect_inventory(inventory: InventoryComponent) -> void:
	if _bound_inventory != null and _bound_inventory.weight_changed.is_connected(_on_weight_changed):
		_bound_inventory.weight_changed.disconnect(_on_weight_changed)
	_bound_inventory = inventory
	panel.bind(inventory)
	if not inventory.weight_changed.is_connected(_on_weight_changed):
		inventory.weight_changed.connect(_on_weight_changed)
	_on_weight_changed(inventory.get_total_weight(), inventory.max_weight)

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


func _on_weight_changed(current: float, maximum: float) -> void:
	if weight_label:
		weight_label.text = "Вес: %.1f / %.1f" % [current, maximum]
