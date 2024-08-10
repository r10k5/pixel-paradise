extends BaseBody

@onready var timer = $Timer
var directions = ["up", "down", "left", "right"]
var current_direction = "down"

func _ready():
	super._ready()
	id = "friendly-entity:frog"
	title = "frog"
	max_health = 25
	health= max_health
	can_be_destroyed = true
	drops = []
	effects = []
	speed = 40
	animations = {
		"idle_up": "idle_up",
		"idle_down": "idle_down",
		"idle_left": "idle_left",
		"idle_right": "idle_right",
		"walk_up": "jump_up",
		"walk_right": "jump_right",
		"walk_left": "jump_left",
		"walk_down": "jump_down",
		#"water_down": "water_down",
		#"water_up": "water_up",
		#"water_left": "water_left",
		#"water_right": "water_right"
	}
	effects_can_be_applied = {}
	can_interact = false
	
	timer.timeout.connect(random_change_state)
	timer.start(5)
	
func random_change_state():
	var state = "idle"
	if  randf() < 0.5:
		state = "walk"
		
	var fsm_state = state + "_" + current_direction
	if fsm_state == fsm.current_state.name:
		random_change_state()
		
	fsm.change_state(fsm.current_state, fsm_state)
	
	if state == "walk":
		timer.start(0.3)
	else:
		timer.start(5)
	
	if state == "idle":
		change_direction()
	
func change_direction():
	current_direction = directions[randi() % directions.size()]
	
func _physics_process(_delta: float):
	move_and_slide()
