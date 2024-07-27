extends Node2D

const CHEST = preload("res://statics/chest/chest.tscn")
const INCREASE_SPEED = preload("res://characters/effects/increase_speed.tscn")
const DECREASE_HP = preload("res://characters/effects/decrease_hp.tscn")
const BOMB = preload("res://statics/bomb/bomb.tscn")
const MAX_CHESTS = 10

@onready var chests = $Chests
@onready var player = $Player
@onready var chest_timer = $ChestTimer
@onready var hp = $HP
@onready var bombs = $Bombs

func on_player_entered_to_chest(chest):
	return func(body):
		if "add_near_entity" in body:
			body.add_near_entity(chest)
	
func on_player_exited_from_chest(chest):
	return func(body):
		if "remove_near_entity" in body:
			body.remove_near_entity(chest)
		
func remove_chest(chest):
	return func():
		if chest in chests.get_children():
			await get_tree().create_timer(0.5).timeout
			
			chests.remove_child(chest)

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
	bomb.on_boom.connect(func(): bombs.remove_child(bomb))
	bombs.add_child(bomb)

func on_hp_changed(current_hp):
	hp.set_hp(current_hp)
	
func generate_effect():
	var effect_id = randi_range(2, 3)
	
	match (effect_id):
		2:
			var speed_effect = INCREASE_SPEED.instantiate()
			speed_effect.use_timeout(5)
			return speed_effect
		3:
			var decrease_hp_effect = DECREASE_HP.instantiate()
			decrease_hp_effect.use_timeout(0.1)
			return decrease_hp_effect

func spawn_chest():
	if len(chests.get_children()) >= MAX_CHESTS:
		return
	
	var chest = CHEST.instantiate()
	var chest_position = Vector2(randf_range(100, 1000), randf_range(100, 550))

	chest.position = chest_position
	
	var area = chest.get_children()[0]
	area.player_entered.connect(on_player_entered_to_chest(area))
	area.player_exited.connect(on_player_exited_from_chest(area))
	area.chest_open.connect(remove_chest(chest))
	area.put_item(generate_effect())
	area.item_dropped.connect(func(item): player.accept_item(item))
	chests.add_child(chest)
