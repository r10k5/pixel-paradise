extends "res://characters/abstract/effect.gd"

const DECREASED_HP = 20

func _init():
	super._init()
	set_item_name("dehp effect")
	set_id(3)
	
func can_apply(entity):
	return super.can_apply(entity) && 'get_health' in entity && 'set_health' in entity
	
func apply(entity):
	var current_hp = entity.get_health()
	entity.set_health(current_hp - DECREASED_HP)
