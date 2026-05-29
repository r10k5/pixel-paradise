extends "res://core/entity/entity.gd"

var damage_amount := 30

func _ready() -> void:
	super._ready()
	id = "passive-entity:bomb"
	max_health = 30
	health = max_health
	animations = {
		"default": "default",
	}
	var area := $Area2D as Area2D
	if area != null:
		area.collision_mask = PhysicsLayers.PLAYER
	play_animation("default")

func _on_animated_sprite_2d_animation_finished() -> void:
	for entity in entities_near:
		if entity is Player:
			entity.take_damage(entity.health)
		else:
			entity.take_damage(damage_amount)
	die()
	queue_free()
