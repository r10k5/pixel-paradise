extends State

class_name WalkDown

@export var base_body: BaseBody
@export var animation: String

func enter():
	base_body.death.connect(set_death_state)
	base_body.play_animation(animation)

func set_death_state():
	transition.emit(self, "death_down")

func exit():
	base_body.death.disconnect(set_death_state)

func update(_delta: float):
	if base_body.velocity.length() == 0:
		transition.emit(self, "idle_down")
	elif base_body.velocity.x > 0:
		transition.emit(self, "walk_right")
	elif base_body.velocity.x < 0:
		transition.emit(self, "walk_left")
	elif base_body.velocity.y < 0:
		transition.emit(self, "walk_up")
