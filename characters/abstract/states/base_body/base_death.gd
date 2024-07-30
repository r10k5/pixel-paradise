extends State

class_name BaseDeath

@export var base_body: BaseBody
@export var animation: String

func enter():
	await base_body.play_animation(animation)
	base_body.queue_free()

func physics_update(_delta: float):
	base_body.speed = 0
	base_body.velocity = Vector2.ZERO
