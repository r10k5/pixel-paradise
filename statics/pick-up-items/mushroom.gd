extends ResourceNode


func _ready() -> void:
	resource_id = "mushroom"
	item_id = "item:mushroom"
	respawn_seconds = 180.0
	PickupIcons.apply_to_animated_sprite($AnimatedSprite2D as AnimatedSprite2D, item_id)
	super._ready()
