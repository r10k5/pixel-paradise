extends CanvasLayer
class_name ToastManager

signal toast_finished

@export_range(1, 10, 1) var max_visible_toasts: int = 5

@onready var toast_list: VBoxContainer = $MarginContainer/ToastList

var pending_queue: Array[Dictionary] = []
var _active_count: int = 0


func _ready() -> void:
	_update_list_visibility()


func show_toast(text: String, duration: float = 2.5, color: Color = Color.WHITE) -> void:
	pending_queue.append({"text": text, "duration": duration, "color": color})
	_try_show_next()


func _try_show_next() -> void:
	while _active_count < max_visible_toasts and not pending_queue.is_empty():
		var data: Dictionary = pending_queue.pop_front()
		_spawn_toast(data)
	_update_list_visibility()


func _spawn_toast(data: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_constant_override("margin_left", 10)
	panel.add_theme_constant_override("margin_right", 10)
	panel.add_theme_constant_override("margin_top", 5)
	panel.add_theme_constant_override("margin_bottom", 5)

	var label := Label.new()
	label.text = str(data.get("text", ""))
	label.add_theme_color_override("font_color", data.get("color", Color.WHITE))

	panel.add_child(label)
	toast_list.add_child(panel)
	toast_list.move_child(panel, 0)

	_active_count += 1
	_update_list_visibility()

	var duration: float = float(data.get("duration", 2.5))
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_on_toast_removed.bind(panel))


func _on_toast_removed(panel: PanelContainer) -> void:
	if is_instance_valid(panel):
		panel.queue_free()
	_active_count = maxi(0, _active_count - 1)
	_try_show_next()
	if _active_count == 0 and pending_queue.is_empty():
		toast_finished.emit()


func _update_list_visibility() -> void:
	if toast_list != null:
		toast_list.visible = _active_count > 0
