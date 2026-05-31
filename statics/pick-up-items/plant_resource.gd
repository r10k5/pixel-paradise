class_name PlantResource
extends ResourceNode


func _apply_world_icon() -> void:
	if item_id.is_empty():
		return
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	PickupIcons.apply_to_animated_sprite(sprite, item_id)
