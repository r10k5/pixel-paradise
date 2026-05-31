extends PlantResource


func _ready() -> void:
	resource_id = "shadow_grass"
	item_id = "item:shadow_grass"
	respawn_seconds = 120.0
	_apply_world_icon()
	super._ready()
