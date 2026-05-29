extends State

class_name BaseJump

@export var base_body: BaseBody
@export var animation: String = "jump_up"
@export var return_idle_state: String = "idle_up"

var _jump_direction: Vector2 = Vector2.ZERO
var _jump_active: bool = false
var _jump_speed: float = 0.0

func enter() -> void:
	_jump_active = true
	_jump_direction = _get_jump_direction()
	var player := base_body as Player
	player.begin_jump()
	_jump_speed = player.compute_jump_speed(animation)
	base_body.velocity = _jump_direction * _jump_speed
	base_body.death.connect(_on_death)
	await base_body.play_animation(animation)
	if _jump_active:
		_return_to_movement()

func exit() -> void:
	_jump_active = false
	base_body.velocity = Vector2.ZERO
	(base_body as Player).end_jump()
	if base_body.death.is_connected(_on_death):
		base_body.death.disconnect(_on_death)

func physics_update(_delta: float) -> void:
	base_body.velocity = _jump_direction * _jump_speed

func _on_death() -> void:
	transition.emit(self, _death_state_name())

func _death_state_name() -> String:
	match name:
		"jump_up":
			return "death_up"
		"jump_down":
			return "death_down"
		_:
			return "death_side"

func _get_jump_direction() -> Vector2:
	return Vector2.ZERO

func _return_to_movement() -> void:
	transition.emit(self, return_idle_state)
