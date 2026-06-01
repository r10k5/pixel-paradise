extends "res://core/entity/entity.gd"

class_name Chest

signal storage_opened(chest: Chest)

enum ChestState { CLOSED, OPEN }

@export var chest_uid: String = ""
@export var loot_table_id: String = "forest_normal"
@export var loot_seed: int = 0
@export var loot_difficulty: String = "normal"
@export var default_biome: Biome.BiomeType = Biome.BiomeType.GRASSLAND

@onready var storage: InventoryComponent = $InventoryComponent

var state: ChestState = ChestState.CLOSED
var loot_generated: bool = false
var _highlight: bool = false


func set_loot_generated(value: bool) -> void:
	loot_generated = value

const _NORMAL_MODULATE := Color(1, 1, 1, 1)
const _HIGHLIGHT_MODULATE := Color(1.2, 1.2, 1.0, 1)


func _ready() -> void:
	add_to_group("chests")
	collision_layer = PhysicsLayers.SOLID
	collision_mask = 0
	if chest_uid.is_empty():
		chest_uid = "chest_%d" % get_instance_id()
	super._ready()
	id = "interact-entity:chest"
	can_be_destroyed = false
	max_health = 500
	health = max_health
	animations = {
		"idle": "idle",
		"open": "open",
	}
	play_animation("idle")
	ChestPersistence.load(self)


func interact() -> void:
	var player := _find_player()
	if player == null:
		return
	if not ChestAuthority.request_open(self, player):
		return
	storage_opened.emit(self)


func open_storage() -> void:
	state = ChestState.OPEN
	play_animation("open")


func close_storage() -> void:
	state = ChestState.CLOSED
	play_animation("idle")
	ChestPersistence.save(self)


func set_highlight(enabled: bool) -> void:
	_highlight = enabled
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.modulate = _HIGHLIGHT_MODULATE if enabled else _NORMAL_MODULATE


func _find_player() -> Player:
	for body in entities_near:
		if body is Player:
			return body as Player
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Player:
			return node as Player
	return null


func _input(_event: InputEvent) -> void:
	pass
