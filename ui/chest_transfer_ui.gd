extends Control

signal closed

@onready var root_vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var chest_panel: InventoryPanel = $MarginContainer/VBoxContainer/PanelsHBox/ChestPanel
@onready var player_panel: InventoryPanel = $MarginContainer/VBoxContainer/PanelsHBox/PlayerPanel
@onready var container_manager: Control = $MarginContainer/VBoxContainer/ContainerManager
@onready var warning_label: Label = $MarginContainer/VBoxContainer/WarningLabel

var _chest: Chest

func _ready() -> void:
	visible = false
	chest_panel.set_exit_visible(false)
	player_panel.set_exit_visible(false)
	if container_manager.has_method("setup"):
		container_manager.setup(self, chest_panel, player_panel)
	warning_label.visible = false


func open(chest: Chest, player_inventory: InventoryComponent) -> void:
	if chest == null or chest.storage == null or player_inventory == null:
		return
	_chest = chest
	chest.can_interact = false
	chest_panel.bind(chest.storage)
	player_panel.bind(player_inventory)
	if container_manager.has_method("bind_inventories"):
		container_manager.bind_inventories(chest.storage, player_inventory)
	visible = true
	show_warning("")
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
		ChestAuthority.request_close(_chest, _find_player())
	_chest = null
	closed.emit()


func is_open() -> bool:
	return visible


func show_warning(text: String) -> void:
	if warning_label == null:
		return
	warning_label.text = text
	warning_label.visible = not text.is_empty()


func _find_player() -> Player:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Player:
			return node as Player
	return null
