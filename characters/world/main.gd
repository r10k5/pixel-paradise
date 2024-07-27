extends Node2D

const CHEST = preload("res://statics/chest/chest.tscn")
const INCREASE_SPEED = preload("res://characters/effects/increase_speed.tscn")
const BOMB = preload("res://statics/bomb/bomb.tscn")
const MAX_CHESTS = 10

@onready var chests = $Chests
@onready var player = $Player
@onready var chest_timer = $ChestTimer
@onready var hp = $HP
@onready var bombs = $Bombs

func _ready():
	player.set_speed(200.0)
	player.changed_hp.connect(on_hp_changed)
	chest_timer.timeout.connect(spawn_chest)
	chest_timer.start()
	player.on_use.connect(on_player_use)
	on_hp_changed(player.get_health())

func on_player_use():
	var bomb = BOMB.instantiate()
	bomb.position = player.position + Vector2(40, 0)
	bombs.add_child(bomb)

func on_hp_changed(current_hp):
	hp.set_hp(current_hp)
	
func generate_effect():
	var speed_effect = INCREASE_SPEED.instantiate()
	speed_effect.timeout = 5
	return speed_effect

func spawn_chest():
	if len(chests.get_children()) >= MAX_CHESTS:
		return
	
	var chest = CHEST.instantiate()
	var chest_position = Vector2(randf_range(100, 1000), randf_range(100, 550))

	chest.position = chest_position
	
	chest.drops.push_back(generate_effect())
	chest.chest_open.connect(func(item):
		print(item)
		player.accept_item(item)
	)
	chests.add_child(chest)
