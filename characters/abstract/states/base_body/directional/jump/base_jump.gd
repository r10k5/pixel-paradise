extends State

class_name BaseJump

@export var base_body: BaseBody
@export var animation: String = "jump_up"
@export var return_idle_state: String = "idle_up"

var _jump_direction: Vector2 = Vector2.ZERO
var _jump_active: bool = false
var _jump_began: bool = false
var _jump_speed: float = 0.0
var _jump_elapsed: float = 0.0
var _jump_duration: float = 0.0
var _arc_height: float = 0.0
var _sprite: AnimatedSprite2D

func enter() -> void:
	_jump_active = false
	_jump_began = false
	var player := base_body as Player
	if player != null:
		if not player.try_begin_jump():
			transition.emit(self, return_idle_state)
			return
	_jump_active = true
	_jump_began = true
	_jump_elapsed = 0.0
	_jump_direction = _get_jump_direction()
	if player != null:
		player.begin_jump()
	_jump_duration = player.get_jump_duration(animation)
	_jump_speed = player.compute_jump_speed(animation)
	_arc_height = player.get_jump_arc_height()
	base_body.velocity = _compute_jump_velocity(0.0)
	base_body.death.connect(_on_death)
	_sprite = base_body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_connect_jump_finished()
	base_body.play_animation(animation)

func exit() -> void:
	_jump_active = false
	_disconnect_jump_finished()
	base_body.velocity = Vector2.ZERO
	if _jump_began and base_body is Player:
		(base_body as Player).end_jump()
	_jump_began = false
	if base_body.death.is_connected(_on_death):
		base_body.death.disconnect(_on_death)

func physics_update(delta: float) -> void:
	if not _jump_active:
		return
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

func _connect_jump_finished() -> void:
	if _sprite == null:
		return
	if _sprite.animation_finished.is_connected(_on_jump_animation_finished):
		_sprite.animation_finished.disconnect(_on_jump_animation_finished)
	_sprite.animation_finished.connect(_on_jump_animation_finished, CONNECT_ONE_SHOT)

func _disconnect_jump_finished() -> void:
	if _sprite != null and _sprite.animation_finished.is_connected(_on_jump_animation_finished):
		_sprite.animation_finished.disconnect(_on_jump_animation_finished)

func _on_jump_animation_finished() -> void:
	if not _jump_active:
		return
	_return_to_movement()

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
