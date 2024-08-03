extends State

class_name WalkDown

@export var base_body: BaseBody
@export var animation: String

var xDirection = 0

func enter():
	base_body.death.connect(set_death_state)
	base_body.play_animation(animation)

func set_death_state():
	transition.emit(self, "death_down")

func exit():
	base_body.death.disconnect(set_death_state)

func update(_delta: float):
	base_body.velocity = Vector2(xDirection, 1).normalized() * base_body.speed
	xDirection = 0
	pass
