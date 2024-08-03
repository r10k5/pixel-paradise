extends State

class_name BaseDeath

@export var base_body: BaseBody
@export var animation: String

func enter():
	base_body.velocity = Vector2.ZERO
	await base_body.play_animation(animation)
	base_body.queue_free()
