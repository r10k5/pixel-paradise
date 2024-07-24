extends "res://characters/abstract/effect.gd"

var _entity = null
var _increased_max_health = 0

func _init():
	super._init()
	set_item_name('IMH Effect')
	set_id(1)

func can_apply(entity):
	return super.can_apply(entity) && 'get_max_health' in entity && 'set_max_health' in entity

func apply(entity):
	_entity = entity
	
	var entity_max_health = entity.get_max_health()
	_increased_max_health = floor(entity_max_health * 0.10)
	
	entity.set_max_health(entity_max_health + _increased_max_health)

func _on_effect_end():
	_entity.set_max_health(_entity.get_max_health() - _increased_max_health)
