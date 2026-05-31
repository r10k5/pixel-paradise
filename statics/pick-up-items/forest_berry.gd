extends PlantResource


func _ready() -> void:
	resource_id = "forest_berry"
	item_id = "item:forest_berry"
	respawn_seconds = 120.0
	_apply_atlas_icon(Rect2(96, 864, 32, 32))
	super._ready()
