extends CharacterBody2D

class_name BaseEntity

signal drop_item(item)
signal drop_effect(item)
signal death()
signal health_changed(value: int)

var id = null
var max_health: int = 100
var health: int = max_health
var can_be_destroyed: bool = true
var drops: Array = []
var effects: Array = []
var animations: Dictionary = {}
var effects_can_be_applied: Dictionary = {}

var is_near_player: bool = false
var can_interact: bool = true
var entities_near: Array = []

func _ready():
	set_process(true)
	set_process_input(true)
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func take_damage(amount: int):
	if can_be_destroyed:
		health -= amount
		health_changed.emit(health)
		if health <= 0:
			die()

func die():
	if can_be_destroyed:
		drop_items()
		death.emit()

func drop_items():
	for drop in drops:
		drop_item.emit(drop)
		
func drop_effects():
	for effect in effects:
		drop_effect.emit(effect)

func play_animation(animation_name: String):
	if animation_name in animations:
		$AnimatedSprite2D.play(animations[animation_name])
		return $AnimatedSprite2D.animation_finished

func apply_effect(effect):
	if (
		effect not in $Effects.get_children() and
		effect.id in effects_can_be_applied.keys()
	):
		$Effects.add_child(effect)

func _input(event):
	if event.is_action_pressed("interact") and is_near_player and can_interact:
		interact()

func interact():
	# Логика взаимодействия с объектом
	pass

func _on_Player_nearby(state: bool):
	is_near_player = state
	
func _on_body_entered(body):
	if body not in entities_near:
		entities_near.push_back(body)
		
	if body.name.to_lower() == "player":
		_on_Player_nearby(true)

func _on_body_exited(body):
	if body in entities_near:
		entities_near = entities_near.filter(
			func(entity: BaseEntity): entity != body
		)

	if body.name.to_lower() == "player":
		_on_Player_nearby(false)
