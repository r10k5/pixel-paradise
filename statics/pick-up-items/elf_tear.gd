extends PlantResource


func _ready() -> void:
	resource_id = "elf_tear"
	item_id = "item:elf_tear"
	respawn_seconds = 600.0
	_apply_world_icon()
	super._ready()
