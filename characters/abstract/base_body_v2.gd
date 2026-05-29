extends BaseEntity

class_name BaseBody

@export var speed: float = 10.0

var facing_left: bool = false

@onready var fsm: StateMachine = $FSM
@onready var idle_up: State = $FSM/idle_up

func _ready() -> void:
	fsm.initial_state = idle_up
	fsm.state_entering.connect(_on_fsm_state_entering)

func set_facing_left(value: bool) -> void:
	if facing_left == value:
		return
	facing_left = value
	_apply_sprite_flip()

func _on_fsm_state_entering(_state: State) -> void:
	_apply_sprite_flip()

func _apply_sprite_flip() -> void:
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	if sprite:
		sprite.flip_h = facing_left
