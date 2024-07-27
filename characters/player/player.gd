extends "res://characters/abstract/base-body.gd"

signal on_use

var _entities_near = []

func get_player_direction() -> Vector2:
	var motion = Vector2()
	
	if Input.is_action_pressed("ui_up"):
		motion.y -= 1
		
	if Input.is_action_pressed("ui_down"):
		motion.y += 1
	
	if Input.is_action_pressed("ui_right"):
		motion.x += 1
		
	if Input.is_action_pressed("ui_left"):
		motion.x -= 1
	
	return motion

func add_near_entity(entity):
	if "action" in entity:
		if entity not in _entities_near:
			_entities_near.push_back(entity)

func remove_near_entity(entity):
	if entity in _entities_near:
		_entities_near = _entities_near.filter(func(ent): return entity != ent)

func action():
	if Input.is_action_pressed("interact"):
		for entity in _entities_near:
			entity.action()
			
func use():
	if Input.is_action_just_released("use"):
		on_use.emit()

func _physics_process(_delta):
	action()
	use()
	change_state(map_vector_to_state(get_player_direction()))
	move_and_slide()
