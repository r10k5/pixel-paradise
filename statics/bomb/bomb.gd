extends StaticBody2D

signal on_boom()

const HEALTH_DAMAGE = preload("res://characters/effects/damage.tscn")
var _is_boomed = false
var _entities_near = []

var effect_factory = func():
	var effect = HEALTH_DAMAGE.instantiate()
	
	effect.use_timeout(0.1)
	
	return effect

@onready var bomb_animation = $AnimatedSprite2D

func _ready():
	bomb_animation.play()
	
func boom():
	if _is_boomed:
		return
		
	var effect = effect_factory.call()
	
	for entity in _entities_near:
		entity.accept_item(effect)
	
	on_boom.emit()

func _on_animated_sprite_2d_animation_finished():
	boom()

func _on_area_2d_body_entered(body):
	if "accept_item" in body:
		_entities_near.push_back(body)

func _on_area_2d_body_exited(body):
	var index = _entities_near.find(body)
	
	if index != -1:
		_entities_near.remove_at(index)
