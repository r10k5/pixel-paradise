extends Node2D

const CHEST = preload("res://statics/chest/chest.tscn")
const INCREASE_SPEED = preload("res://characters/effects/increase_speed.tscn")
const BOMB = preload("res://statics/bomb/bomb.tscn")
const TREE = preload("res://statics/tree/tree.tscn")
const FROG = preload("res://characters/friendly_entities/frog/frog.tscn")
const MUSHROOM = preload("res://statics/mushrooms/mushroom.tscn")
const KUST = preload("res://statics/tree/kust.tscn")

const MAX_MUSHROOM = 2
const MAX_FROGS = 1
const MAX_TREES = 10
const MAX_KUSTI = 10

@onready var player: Player = $Player
@onready var hp_bar = $UI/HP
@onready var trees = $Entities/Trees
@onready var droped_items = $Entities/DropItems
@onready var timer = $Entities/Chests/ChestTimer
@onready var inventory = $UI/Inventory
@onready var full_inventory = $UI/FullInventory/FullInventory
@onready var frogs = $Frogs
@onready var mushrooms = $Entities/Mushrooms
@onready var kusti = $Entities/Kusti

var occupied_positions = []

func _input(event):
	if event.is_action_released("inventory"):
		full_inventory.show()
		
func _ready():
	player.health_changed.connect(on_health_changed)
	player.inventory.item_add.connect(on_add_item_to_inventory)
	full_inventory.connect_inventory(player.inventory)
	on_health_changed(player.health)
	timer.timeout.connect(spawn_all)
	# timer.timeout.connect(spawn_tree)
	# timer.timeout.connect(spawn_frog)
	
func on_health_changed(current_health: int):
	hp_bar.set_hp(current_health)

func is_position_occupied(position: Vector2) -> bool:
	for occupied_position in occupied_positions:
		if position.distance_to(occupied_position) < 50:  # Замените 50 на радиус проверки
			return true
	return false

func get_free_position() -> Vector2:
	var position = Vector2(randf_range(100, 1000), randf_range(100, 550))
	while is_position_occupied(position):
		position = Vector2(randf_range(100, 1000), randf_range(100, 550))
	return position

func spawn_all():
	# Spawn trees
	while len(trees.get_children()) < MAX_TREES:
		var tree = TREE.instantiate()
		var tree_position = get_free_position()
		tree.position = tree_position
		occupied_positions.append(tree_position)
		trees.add_child(tree)
		break

	# Spawn frogs
	while len(frogs.get_children()) < MAX_FROGS:
		var frog = FROG.instantiate()
		var frog_position = get_free_position()
		frog.position = frog_position
		occupied_positions.append(frog_position)
		frogs.add_child(frog)
		break

	# Spawn mushrooms
	while len(mushrooms.get_children()) < MAX_MUSHROOM:
		var mushroom = MUSHROOM.instantiate()
		var mushroom_position = get_free_position()
		mushroom.position = mushroom_position
		occupied_positions.append(mushroom_position)
		mushrooms.add_child(mushroom)
		break

	# Spawn kust
	while len(kusti.get_children()) < MAX_KUSTI:
		var kust = KUST.instantiate()
		var kust_position = get_free_position()
		kust.position = kust_position
		occupied_positions.append(kust_position)
		kusti.add_child(kust)
		break

func _on_item_pick_up(item: BaseEntity):
	if item in item.get_parent().get_children():
		player.inventory.add_item(item)
		item.get_parent().remove_child(item)

func on_item_pick_up(item: BaseEntity):
	if player in item.entities_near:
		call_deferred("_on_item_pick_up", item)
		
func on_add_item_to_inventory(item: InventoryItem):
	inventory.on_add_item(item)
