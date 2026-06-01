extends State

class_name BaseJump

@export var base_body: BaseBody
@export var animation: String = "jump_up"
@export var return_idle_state: String = "idle_up"

var _jump_direction: Vector2 = Vector2.ZERO
var _jump_active: bool = false
var _jump_speed: float = 0.0
var _jump_elapsed: float = 0.0
var _jump_duration: float = 0.0
var _arc_height: float = 0.0

func enter() -> void:
	var player := base_body as Player
	if player != null:
		if not player.try_begin_jump():
			transition.emit(self, return_idle_state)
			return
	_jump_active = true
	_jump_elapsed = 0.0
	_jump_direction = _get_jump_direction()
	if player != null:
		player.begin_jump()
	_jump_duration = player.get_jump_duration(animation)
	_jump_speed = player.compute_jump_speed(animation)
	_arc_height = player.get_jump_arc_height()
	base_body.velocity = _compute_jump_velocity(0.0)
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

func physics_update(delta: float) -> void:
	_jump_elapsed += delta
	var progress := clampf(_jump_elapsed / _jump_duration, 0.0, 1.0) if _jump_duration > 0.0 else 1.0
	base_body.velocity = _compute_jump_velocity(progress)

func _compute_jump_velocity(progress: float) -> Vector2:
	var velocity := _jump_direction * _jump_speed
	if _arc_height <= 0.0 or _jump_duration <= 0.0:
		return velocity
	# Дуга только для бокового прыжка — иначе jump_down сначала тянет вверх.
	if absf(_jump_direction.y) >= 0.99:
		return velocity
	var arc_velocity_y := -_arc_height * PI / _jump_duration * cos(PI * progress)
	return velocity + Vector2(0.0, arc_velocity_y)

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
