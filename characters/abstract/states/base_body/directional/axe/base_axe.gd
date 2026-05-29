extends State

class_name BaseAxe

@export var base_body: BaseBody
@export var animation: String
@export var return_idle_state: String = "idle_up"

const HIT_FRAME := 2

var _hit_applied := false
var _sprite: AnimatedSprite2D

func enter() -> void:
	_hit_applied = false
	base_body.velocity = Vector2.ZERO
	base_body.death.connect(_on_death)
	_sprite = base_body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if _sprite:
		_sprite.frame_changed.connect(_on_frame_changed)
	await base_body.play_animation(animation)
	_return_to_movement()

func exit() -> void:
	if _sprite and _sprite.frame_changed.is_connected(_on_frame_changed):
		_sprite.frame_changed.disconnect(_on_frame_changed)
	if base_body.death.is_connected(_on_death):
		base_body.death.disconnect(_on_death)

func _on_frame_changed() -> void:
	if _hit_applied or _sprite == null or _sprite.frame < HIT_FRAME:
		return
	_hit_applied = true
	_apply_hit()

func _apply_hit() -> void:
	var player := base_body as Player
	if player:
		player.try_chop_tree(_get_attack_direction())

func _get_attack_direction() -> Vector2:
	return Vector2.ZERO

func _on_death() -> void:
	transition.emit(self, _death_state_name())

func _death_state_name() -> String:
	match name:
		"axe_up":
			return "death_up"
		"axe_down":
			return "death_down"
		_:
			return "death_side"

func _return_to_movement() -> void:
	transition.emit(self, return_idle_state)
