extends Control

class_name InventoryCell

signal cell_pressed(cell: InventoryCell)

var inventory_item: InventoryItem
var bound_inventory: InventoryComponent
var slot_id: int = -1

@onready var item_count_lable = $ItemCount
@onready var item_texture_node = $TextureRect
@onready var background = $Background

var _tooltip: Label

const SELECTED_TINT := Color(1.15, 1.15, 0.75)
const NORMAL_TINT := Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	_setup_tooltip()
	refresh()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			cell_pressed.emit(self)


func _setup_tooltip() -> void:
	_tooltip = Label.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip)


func bind(inventory: InventoryComponent, p_slot_id: int) -> void:
	bound_inventory = inventory
	slot_id = p_slot_id
	inventory_item = inventory.get_item(p_slot_id)
	if is_node_ready():
		refresh()


func replace(item: InventoryItem) -> void:
	if item != null:
		slot_id = item.id
		inventory_item = item
	refresh()


func refresh() -> void:
	if is_node_ready():
		_update_display()


func _get_slot_item() -> InventoryItem:
	if bound_inventory != null and slot_id >= 0:
		return bound_inventory.get_item(slot_id)
	return inventory_item


func _get_item_texture(item: BaseEntity) -> Texture2D:
	if item == null:
		return null
	if item.texture != null:
		return item.texture
	if item.id != null:
		return PickupIcons.get_texture(str(item.id))
	return null


func _update_display() -> void:
	if item_texture_node == null or item_count_lable == null:
		return
	var slot_item := _get_slot_item()
	if slot_item != null and slot_item.item:
		item_texture_node.texture = _get_item_texture(slot_item.item)
		item_count_lable.text = str(slot_item.count) if slot_item.count > 1 else ""
	else:
		item_texture_node.texture = null
		item_count_lable.text = ""
	_update_tooltip_text()
	_sync_tooltip_visibility()


func set_selected(selected: bool) -> void:
	if background:
		background.modulate = SELECTED_TINT if selected else NORMAL_TINT


func _get_drag_data(_at_position: Vector2) -> Variant:
	var slot_item := _get_slot_item()
	if slot_item == null or slot_item.is_empty() or bound_inventory == null:
		return null
	var drag_tex := _get_item_texture(slot_item.item)
	if drag_tex == null:
		return null

	var preview := TextureRect.new()
	preview.texture = drag_tex
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.custom_minimum_size = Vector2(48, 48)
	set_drag_preview(preview)

	var payload := {
		"inventory": bound_inventory,
		"slot_id": slot_id,
		"from_player": bound_inventory != null and bound_inventory.get_parent() is Player,
	}
	DragDropManager.notify_drag_started(payload)
	if _tooltip:
		_tooltip.visible = false
	return payload


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if bound_inventory == null or slot_id < 0 or not data is Dictionary:
		return false
	if not data.has("inventory") or not data.has("slot_id"):
		return false
	var from_inventory: InventoryComponent = data["inventory"]
	var from_id: int = data["slot_id"]
	if from_inventory == bound_inventory and from_id == slot_id:
		return false
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from_inventory: InventoryComponent = data["inventory"]
	var from_id: int = data["slot_id"]
	InventoryComponent.transfer_between(from_inventory, from_id, bound_inventory, slot_id)


func _should_show_tooltip() -> bool:
	if DragDropManager.is_drag_active():
		return false
	var slot_item := _get_slot_item()
	return slot_item != null and not slot_item.is_empty()


func _sync_tooltip_visibility() -> void:
	if _tooltip == null:
		return
	if not _should_show_tooltip():
		_tooltip.visible = false
		return
	if get_viewport() != null and get_global_rect().has_point(get_global_mouse_position()):
		_tooltip.visible = true
		_position_tooltip()


func _on_mouse_entered() -> void:
	if not _should_show_tooltip():
		return
	if _tooltip:
		_tooltip.visible = true
		_position_tooltip()


func _on_mouse_exited() -> void:
	if _tooltip:
		_tooltip.visible = false


func _position_tooltip() -> void:
	if _tooltip == null:
		return
	_tooltip.position = Vector2(size.x + 4, 0)


func _update_tooltip_text() -> void:
	if _tooltip == null:
		return
	var slot_item := _get_slot_item()
	if slot_item == null or slot_item.is_empty():
		_tooltip.text = ""
		return
	var item := slot_item.item
	var weight_line := "%.1f kg" % (item.item_weight * float(slot_item.count))
	_tooltip.text = "%s\n%d / %d\n%s" % [
		item.title,
		slot_item.count,
		item.stack_size,
		weight_line,
	]
