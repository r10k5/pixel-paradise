class_name ScreenCullRegion
extends Node2D
## Скрывает дочерние CanvasItem и отключает _process вне экрана (frustum culling).

@export var cull_when_off_screen: bool = true
@export var disable_process_when_culled: bool = true

@onready var _notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var _on_screen: bool = true
var _content: Array[Node] = []


func _ready() -> void:
	_notifier.screen_entered.connect(_on_screen_entered)
	_notifier.screen_exited.connect(_on_screen_exited)
	call_deferred("_sync_initial_visibility")


func _sync_initial_visibility() -> void:
	_on_screen = _notifier.is_on_screen()
	_apply_on_screen(_on_screen)


func set_cull_rect(rect: Rect2) -> void:
	_notifier.rect = rect


func register_content(node: Node) -> void:
	if node == _notifier:
		return
	if node not in _content:
		_content.append(node)


func register_canvas_items_under(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			register_content(child)
		register_canvas_items_under(child)


func _on_screen_entered() -> void:
	_on_screen = true
	_apply_on_screen(true)


func _on_screen_exited() -> void:
	_on_screen = false
	_apply_on_screen(false)


func is_region_on_screen() -> bool:
	return _on_screen


func _apply_on_screen(on_screen: bool) -> void:
	if not cull_when_off_screen:
		return
	for node in _content:
		if not is_instance_valid(node):
			continue
		if node is CanvasItem:
			(node as CanvasItem).visible = on_screen
		if disable_process_when_culled and node is Node:
			(node as Node).process_mode = (
				Node.PROCESS_MODE_INHERIT if on_screen else Node.PROCESS_MODE_DISABLED
			)
