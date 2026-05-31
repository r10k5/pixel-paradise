extends PlantResource


func _ready() -> void:
	resource_id = "oak_root"
	item_id = "item:oak_root"
	respawn_seconds = 300.0
	_apply_atlas_icon(Rect2(384, 480, 32, 32))
	super._ready()
