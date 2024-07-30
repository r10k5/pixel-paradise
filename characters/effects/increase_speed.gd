extends "res://characters/abstract/effect.gd"

var _entity = null
var _increased_speed = 0.0

func _init():
	id = "effect:increase-speed"
	effect_end.connect(_on_effect_end)

func apply(entity):
	_entity = entity
	
	var entity_speed = entity.get_speed()
	_increased_speed = floorf(entity_speed * 1)
	
	entity.set_speed(entity_speed + _increased_speed)

func _on_effect_end(_effect):
	_entity.set_speed(_entity.get_speed() - _increased_speed)
