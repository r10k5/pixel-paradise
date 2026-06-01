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

func update(_delta: float) -> void:
	var vertical := Input.is_action_pressed("move_down")
	if not vertical:
		base_body.velocity = Vector2.ZERO
		_reset_walk_sprint()
		xDirection = 0
		return
	var dir := Vector2(xDirection, 1.0)
	var spd := _walk_speed(true)
	base_body.velocity = dir.normalized() * spd
	xDirection = 0


func _walk_speed(direction_active: bool) -> float:
	if base_body is Player:
		return (base_body as Player).compute_walk_speed(direction_active)
	return base_body.speed


func _reset_walk_sprint() -> void:
	if base_body is Player:
		(base_body as Player).compute_walk_speed(false)
