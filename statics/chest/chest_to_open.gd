extends Area2D

signal player_entered(body)
signal player_exited(body)
signal chest_open()
signal item_dropped(item)

@onready var tooltip = $Tooltip
@onready var anim = $"../AnimatedSprite2D"

var _is_opened = false
var _items = []

func open():
	_is_opened = true
	chest_open.emit()
	anim.play("open")
	tooltip.visible = false
	
	for item in _items:
		item_dropped.emit(item)

func put_item(item):
	if not _is_opened and item not in _items:
		_items.push_back(item)
		
func has_item(item):
	return item in _items
		
func get_items():
	if _is_opened:
		return _items
		
	return []

func action():
	if not _is_opened:
		open()

func _on_body_entered(body):
	if body.name == "Player" and !_is_opened:
		player_entered.emit(body)
		tooltip.visible = true


func _on_body_exited(body):
	if body.name == "Player":
		player_exited.emit(body)
		tooltip.visible = false
