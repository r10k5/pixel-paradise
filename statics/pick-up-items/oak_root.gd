extends PlantResource


func _ready() -> void:
	resource_id = "oak_root"
	item_id = "item:oak_root"
	respawn_seconds = 300.0
	_apply_world_icon()
	super._ready()
