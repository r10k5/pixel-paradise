extends BaseEntity

class_name BaseBody

@export var speed: float = 10.0

@onready var fsm: StateMachine = $FSM
@onready var idle_up: State = $FSM/idle_up

func _ready():
	fsm.initial_state = idle_up

func move_right():
	velocity = Vector2(1, 0)
	
func move_left():
	velocity = Vector2(-1, 0)
	
func move_up():
	velocity = Vector2(0, -1)
	
func move_down():
	velocity = Vector2(0, 1)
