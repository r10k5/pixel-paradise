extends PickupItem

const MUSHROOM_TEX := preload("res://assets/world/static/mushroom-texture.png")


func _init() -> void:
	_configure("item:mushroom", "Гриб", 30, 0.25)


func _ready() -> void:
	texture = MUSHROOM_TEX
	super._ready()
