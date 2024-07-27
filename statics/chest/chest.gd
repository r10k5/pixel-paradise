extends "res://Entity.gd"

signal chest_open(items)

func _ready():
	super._ready()
	
	id = "interact-entity:chest"
	max_health = 500
	health = max_health
	animations = {
		"idle": "idle",
		"open": "open"
	}
	play_animation("idle")

func interact():
	play_animation("open")
	chest_open.emit(drops)
	
	# Это временно
	await get_tree().create_timer(0.5).timeout
	die()
