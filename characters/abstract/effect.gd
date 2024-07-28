extends Node

signal effect_end(effect)

var id = null
var timeout = null

func _ready():
	if timeout:
		get_tree().create_timer(timeout).timeout.connect(
			func():
				effect_end.emit(self)
				queue_free()
		)

func _process(_delta):
	pass
	
func apply(_entity):
	pass
