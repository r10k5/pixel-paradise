extends PickupItem


func _init() -> void:
	_configure("item:mushroom", "Гриб", 30, 0.25)
	hunger_restore = 15.0
	stamina_restore = 10.0
