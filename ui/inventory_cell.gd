extends Control

class_name InventoryCell

var inventory_item: InventoryItem
var bound_inventory: InventoryComponent
var slot_id: int = -1

@onready var item_count_lable = $ItemCount
@onready var item_texture_node = $TextureRect
@onready var background = $Background

var _tooltip: PanelContainer

const SELECTED_TINT := Color(1.15, 1.15, 0.75)
const NORMAL_TINT := Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_setup_tooltip()
	refresh()


func _setup_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.name = "TooltipLabel"
	_tooltip.add_child(label)
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


func _update_display() -> void:
	if item_texture_node == null or item_count_lable == null:
		return
	var slot_item := _get_slot_item()
	if slot_item != null and slot_item.item:
		item_texture_node.texture = slot_item.item.texture
		item_count_lable.text = str(slot_item.count) if slot_item.count > 1 else ""
	else:
		item_texture_node.texture = null
		item_count_lable.text = ""
	_update_tooltip_text()


func set_selected(selected: bool) -> void:
	if background:
		background.modulate = SELECTED_TINT if selected else NORMAL_TINT


func _get_drag_data(_at_position: Vector2) -> Variant:
	var slot_item := _get_slot_item()
	if slot_item == null or slot_item.is_empty() or bound_inventory == null:
		return null
	if slot_item.item.texture == null:
		return null

	var preview := TextureRect.new()
	preview.texture = slot_item.item.texture
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.custom_minimum_size = Vector2(48, 48)
	set_drag_preview(preview)

	return {
		"inventory": bound_inventory,
		"slot_id": slot_id,
	}


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


func _on_mouse_entered() -> void:
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
	var label := _tooltip.get_node_or_null("TooltipLabel") as Label
	if label == null:
		return
	var slot_item := _get_slot_item()
	if slot_item == null or slot_item.is_empty():
		label.text = ""
		return
	var item := slot_item.item
	var weight_line := "%.1f kg" % (item.item_weight * float(slot_item.count))
	label.text = "%s\n%d / %d\n%s" % [
		item.title,
		slot_item.count,
		item.stack_size,
		weight_line,
	]
