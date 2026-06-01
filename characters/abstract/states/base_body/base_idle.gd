extends State

class_name BaseIdle

@export var base_body: BaseBody
@export var animation: String
@export var death_state: BaseDeath

func enter():
	base_body.death.connect(set_death_state)
	base_body.play_animation(animation)
	base_body.velocity = Vector2(0, 0)
	_reset_player_sprint()

func set_death_state():
	transition.emit(self, death_state.name)

func exit():
	base_body.death.disconnect(set_death_state)

func update(_delta: float) -> void:
	_reset_player_sprint()


func _reset_player_sprint() -> void:
	if base_body is Player:
		(base_body as Player).compute_walk_speed(false)
