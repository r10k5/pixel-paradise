extends PlantResource


func _ready() -> void:
	resource_id = "elf_tear"
	item_id = "item:elf_tear"
	respawn_seconds = 600.0
	_apply_atlas_icon(Rect2(64, 480, 32, 32))
	super._ready()
