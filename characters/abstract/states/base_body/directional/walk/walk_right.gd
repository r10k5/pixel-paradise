extends State

class_name WalkRight

@export var base_body: BaseBody
@export var animation: String

func enter():
	base_body.death.connect(set_death_state)
	base_body.play_animation(animation)

func set_death_state():
	transition.emit(self, "death_right")

func exit():
	base_body.death.disconnect(set_death_state)

func update(_delta: float):
	base_body.velocity = Vector2(1, 0).normalized() * base_body.speed
	pass
