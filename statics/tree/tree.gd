extends "res://Entity.gd"

func _ready():
	super._ready()
	id = "passive-entity:tree"
	max_health = 10
	health = max_health
	drops = []
	animations = {}

	can_interact = false
