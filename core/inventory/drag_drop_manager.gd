extends Node

var _active_drag: Dictionary = {}
var _tooltip: Label


func _ready() -> void:
	_tooltip = Label.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 1000
	add_child(_tooltip)


func is_drag_active() -> bool:
	return not _active_drag.is_empty()


func notify_drag_started(data: Dictionary) -> void:
	_active_drag = data.duplicate()


func _input(event: InputEvent) -> void:
	if _active_drag.is_empty():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_finish_drag()
	_clear_highlights()
	if not _active_drag.is_empty() and _active_drag.get("from_player", false):
		var chest := _chest_under_mouse()
		if chest != null:
			chest.set_highlight(true)
			if _tooltip:
				_tooltip.visible = true
				_tooltip.text = "Отпустить, чтобы положить"
				_tooltip.global_position = get_viewport().get_mouse_position() + Vector2(12, 12)
		elif _tooltip:
			_tooltip.visible = false


func _finish_drag() -> void:
	if _active_drag.is_empty():
		return
	if not _active_drag.get("from_player", false):
		_active_drag.clear()
		return
	var chest := _chest_under_mouse()
	if chest == null:
		_active_drag.clear()
		return
	var player := _find_player()
	var inv: InventoryComponent = _active_drag.get("inventory")
	var slot_id: int = _active_drag.get("slot_id", -1)
	if player != null and inv != null:
		if ChestAuthority.request_direct_deposit(chest, inv, slot_id, player):
			inv.contents_changed.emit()
			if player.inventory != null:
				player.inventory.contents_changed.emit()
	_active_drag.clear()
	if _tooltip:
		_tooltip.visible = false


func _chest_under_mouse() -> Chest:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("chests"):
		if not node is Chest:
			continue
		var chest := node as Chest
		if chest.state == Chest.ChestState.OPEN:
			continue
		if chest.global_position.distance_to(_world_mouse_pos()) > ChestAuthority.MAX_INTERACT_DISTANCE:
			continue
		return chest
	return null


func _world_mouse_pos() -> Vector2:
	var tree := get_tree()
	if tree == null:
		return Vector2.ZERO
	var cam := tree.root.get_viewport().get_camera_2d()
	if cam == null:
		return Vector2.ZERO
	return cam.get_global_mouse_position()


func _find_player() -> Player:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Player:
			return node as Player
	return null


func _clear_highlights() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("chests"):
		if node is Chest:
			(node as Chest).set_highlight(false)
