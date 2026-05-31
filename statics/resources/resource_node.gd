class_name ResourceNode
extends Area2D

signal harvested(node: ResourceNode)

@export var resource_id: String = ""
@export var item_id: String = ""
@export var respawn_seconds: float = 120.0

var spawn_tile: Vector2i = Vector2i.ZERO
var _harvested: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitoring = true
	body_entered.connect(_on_body_entered)


func set_spawn_tile(tile: Vector2i) -> void:
	spawn_tile = tile


func _on_body_entered(body: Node2D) -> void:
	if _harvested:
		return
	if body is Player:
		_harvest()


func _harvest() -> void:
	if _harvested:
		return
	_harvested = true
	harvested.emit(self)
	queue_free()
