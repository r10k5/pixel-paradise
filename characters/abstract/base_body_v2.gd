extends BaseEntity

class_name BaseBody

@export var speed: float = 10.0

@onready var fsm: StateMachine = $FSM
@onready var idle_up: State = $FSM/idle_up

func _ready():
	fsm.initial_state = idle_up
