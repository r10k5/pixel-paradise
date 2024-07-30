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

#@onready var chests = $Chests
#@onready var player = $Player
#@onready var chest_timer = $ChestTimer
#@onready var bombs = $Bombs
#
#func _ready():
	#player.set_speed(200.0)
	#player.changed_hp.connect(on_hp_changed)
	#chest_timer.timeout.connect(spawn_chest)
	#chest_timer.start()
	#player.on_use.connect(on_player_use)
	#on_hp_changed(player.get_health())
#
#func on_player_use():
	#var bomb = BOMB.instantiate()
	#bomb.position = player.position + Vector2(40, 0)
	#bombs.add_child(bomb)
#

	#
#func generate_effect():
	#var speed_effect = INCREASE_SPEED.instantiate()
	#speed_effect.timeout = 5
	#return speed_effect
#
#func spawn_chest():
	#if len(chests.get_children()) >= MAX_CHESTS:
		#return
	#
	#var chest = CHEST.instantiate()
	#var chest_position = Vector2(randf_range(100, 1000), randf_range(100, 550))
#
	#chest.position = chest_position
	#
	#chest.drops.push_back(generate_effect())
	#chest.chest_open.connect(func(item):
		#print(item)
		#player.accept_item(item)
	#)
	#chests.add_child(chest)
