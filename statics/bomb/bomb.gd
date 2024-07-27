extends "res://Entity.gd"

var damage_amount = 30

func _ready():
	super._ready()
	
	id = "passive-entity:bomb"
	max_health = 30
	health = max_health
	animations = {
		"default": "default",
	}
	play_animation("default")

func _on_animated_sprite_2d_animation_finished():
	for entity in entities_near:
		entity.take_damage(damage_amount)
	die()
