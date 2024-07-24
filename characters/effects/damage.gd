extends "res://characters/abstract/effect.gd"

var damage = 20

func _init():
	super._init()
	set_item_name("damage_effect")
	set_id(4)
	
func can_apply(entity):
	return super.can_apply(entity) && 'take_damage' in entity
	
func apply(entity):
	entity.take_damage(damage)
