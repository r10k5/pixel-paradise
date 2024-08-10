extends Node2D

const CHEST = preload("res://statics/chest/chest.tscn")
const INCREASE_SPEED = preload("res://characters/effects/increase_speed.tscn")
const BOMB = preload("res://statics/bomb/bomb.tscn")
const MAX_TREES = 10
const TREE = preload("res://statics/tree/tree.tscn")
const FROG = preload("res://characters/friendly_entities/frog.tscn")
const MAX_FROGS = 10

@onready var player: Player = $Player
@onready var hp_bar = $UI/HP
@onready var trees = $Entities/Trees
@onready var droped_items = $Entities/DropItems
@onready var timer = $Entities/Chests/ChestTimer
@onready var inventory = $UI/Inventory
@onready var full_inventory = $UI/FullInventory/FullInventory
@onready var frogs = $Frogs

func _input(event):
	if event.is_action_released("inventory"):
		full_inventory.show()
		
func _ready():
	player.health_changed.connect(on_health_changed)
	player.inventory.item_add.connect(on_add_item_to_inventory)
	full_inventory.connect_inventory(player.inventory)
	on_health_changed(player.health)
	timer.timeout.connect(spawn_tree)
	timer.timeout.connect(spawn_frog)
	
func on_health_changed(current_health: int):
	hp_bar.set_hp(current_health)

func spawn_tree():
	if len(trees.get_children()) >= MAX_TREES:
		return
	
	var tree = TREE.instantiate()
	var tree_position = Vector2(randf_range(100, 1000), randf_range(100, 550))

	tree.position = tree_position
	
	tree.drop_item.connect(func(item):
		item.position = tree.position
		item.pick_up.connect(on_item_pick_up)
		droped_items.add_child(item)
	)
	trees.add_child(tree)

func _on_item_pick_up(item: BaseEntity):
	if item in droped_items.get_children():
		player.inventory.add_item(item)
		droped_items.remove_child(item)
	

func on_item_pick_up(item: BaseEntity):
	if player in item.entities_near:
		call_deferred("_on_item_pick_up", item)
		
func on_add_item_to_inventory(item: InventoryItem):
	inventory.on_add_item(item)


func spawn_frog():
	if len(frogs.get_children()) >= MAX_FROGS:
		return
	
	var frog = FROG.instantiate()
	var frog_position = Vector2(randf_range(100, 1000), randf_range(100, 550))

	frog.position = frog_position
	
	frogs.add_child(frog)
