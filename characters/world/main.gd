extends Node2D

const CHEST = preload("res://statics/chest/chest.tscn")
const INCREASE_SPEED = preload("res://characters/effects/increase_speed.tscn")
const BOMB = preload("res://statics/bomb/bomb.tscn")
const MAX_TREES = 10
const TREE = preload("res://statics/tree/tree.tscn")

@onready var player = $Player
@onready var hp_bar = $HP
@onready var trees = $Trees
@onready var droped_items = $DropItems
@onready var timer = $ChestTimer
@onready var inventory = $Inventory
@onready var full_inventory = $CanvasLayer/FullInventory

func _input(event):
	if event.is_action_released("inventory"):
		full_inventory.show()
		
func _ready():
	player.health_changed.connect(on_health_changed)
	on_health_changed(player.health)
	timer.timeout.connect(spawn_tree)
	
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

func on_item_pick_up(item: BaseEntity):
	if player in item.entities_near:
		inventory.add_item_to_inventory(item)
		item.queue_free()
