extends Control

signal transfer_result(result: ChestTransferResult)

@onready var take_all_btn: Button = $HBoxContainer/TakeAllButton
@onready var give_all_btn: Button = $HBoxContainer/GiveAllButton
@onready var similar_btn: Button = $HBoxContainer/SimilarButton
@onready var close_btn: Button = $HBoxContainer/CloseButton

var _chest_ui: Control
var _chest_panel: InventoryPanel
var _player_panel: InventoryPanel
var _chest_storage: InventoryComponent
var _player_inventory: InventoryComponent


func setup(chest_ui: Control, chest_panel: InventoryPanel, player_panel: InventoryPanel) -> void:
	_chest_ui = chest_ui
	_chest_panel = chest_panel
	_player_panel = player_panel
	if take_all_btn:
		take_all_btn.pressed.connect(_on_take_all)
	if give_all_btn:
		give_all_btn.pressed.connect(_on_give_all)
	if similar_btn:
		similar_btn.pressed.connect(_on_similar)
	if close_btn:
		close_btn.pressed.connect(_on_close)


func bind_inventories(chest_storage: InventoryComponent, player_inventory: InventoryComponent) -> void:
	_chest_storage = chest_storage
	_player_inventory = player_inventory


func _on_take_all() -> void:
	_apply_bulk(_chest_storage, _player_inventory, ChestAuthority.BulkMode.ALL, "")


func _on_give_all() -> void:
	_apply_bulk(_player_inventory, _chest_storage, ChestAuthority.BulkMode.ALL, "")


func _on_similar() -> void:
	var chest_id := _chest_panel.get_selected_item_id()
	var player_id := _player_panel.get_selected_item_id()
	if not chest_id.is_empty():
		_apply_bulk(_chest_storage, _player_inventory, ChestAuthority.BulkMode.SIMILAR, chest_id)
	elif not player_id.is_empty():
		_apply_bulk(_player_inventory, _chest_storage, ChestAuthority.BulkMode.SIMILAR, player_id)
	else:
		_emit_message("Выберите предмет в сетке")


func _get_selected_item_id() -> String:
	var id := _chest_panel.get_selected_item_id()
	if not id.is_empty():
		return id
	return _player_panel.get_selected_item_id()


func _apply_bulk(from_inv: InventoryComponent, to_inv: InventoryComponent, mode: ChestAuthority.BulkMode, filter_id: String) -> void:
	var result := ChestAuthority.request_bulk_move(from_inv, to_inv, mode, filter_id)
	_chest_panel.refresh_all()
	_player_panel.refresh_all()
	transfer_result.emit(result)
	if not result.message.is_empty() and _chest_ui != null and _chest_ui.has_method("show_warning"):
		_chest_ui.show_warning(result.message)


func _on_close() -> void:
	if _chest_ui != null and _chest_ui.has_method("close"):
		_chest_ui.close()


func _emit_message(msg: String) -> void:
	var result := ChestTransferResult.new()
	result.message = msg
	transfer_result.emit(result)
	if _chest_ui != null and _chest_ui.has_method("show_warning"):
		_chest_ui.show_warning(msg)
