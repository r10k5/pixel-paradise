extends "res://core/entity/entity.gd"

class_name Chest

signal storage_opened(chest: Chest)

var storage: Inventory

func _ready() -> void:
	if storage == null:
		storage = Inventory.new()
	collision_layer = PhysicsLayers.SOLID
	collision_mask = 0
	super._ready()

	id = "interact-entity:chest"
	can_be_destroyed = false
	max_health = 500
	health = max_health
	animations = {
		"idle": "idle",
		"open": "open"
	}
	play_animation("idle")

func interact() -> void:
	play_animation("open")
	storage_opened.emit(self)

func close_storage() -> void:
	play_animation("idle")

func _input(_event: InputEvent) -> void:
	pass
